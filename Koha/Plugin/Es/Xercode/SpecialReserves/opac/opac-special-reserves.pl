#!/usr/bin/perl

# Copyright Xercode 2019
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use utf8;

use Modern::Perl;

use CGI;

use C4::Auth;
use C4::Output;
use C4::Context;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use Mail::Sendmail;
use Koha::Email;
use Carp;
use Encode qw(encode);
use MIME::QuotedPrint;
use Koha::Plugins::Handler;
use HTML::Entities;

my $cgi = new CGI;
my $op = $cgi->param('op') || 0;
my $biblionumber = $cgi->param('biblionumber') || 0;

my $pluginDir = dirname(abs_path($0));

my $thisPlugin_enabled = Koha::Plugins::Handler->run( { class => 'Koha::Plugin::Es::Xercode::SpecialReserves', method => 'opac_special_reserves' } );
my $biblio = Koha::Biblios->find( $biblionumber );
my $record = C4::Biblio::GetMarcBiblio({ biblionumber => $biblio->id });
my $bibliodata;
$bibliodata->{title} = $record->subfield('245',"a")." ".$record->subfield('245',"b");
$bibliodata->{author} = ( $record->subfield('245',"c") ) ? $record->subfield('245',"c") : "";

if ( !$biblionumber || !$thisPlugin_enabled || !$biblio ) {
    print $cgi->redirect("/cgi-bin/koha/errors/404.pl");
    exit;
}

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name   => "$pluginDir/opac-reserves-begin.tt",
        query           => $cgi,
        type            => "opac",
        authnotrequired => 0,
        debug           => 1,
    }
);

my $canBeReserved = Koha::Plugins::Handler->run( { class => 'Koha::Plugin::Es::Xercode::SpecialReserves', method => 'can_be_reserved', params => $biblio } );
my $translations = Koha::Plugins::Handler->run( { class => 'Koha::Plugin::Es::Xercode::SpecialReserves', method => 'get_text_labels' } );

if ( !$$translations{txt_cantbereserved} ){
    print $cgi->redirect("/cgi-bin/koha/errors/404.pl");
    exit;
}
if ( !$canBeReserved ){
    $template->param( error => 1 );
    $template->param( msg => $$translations{txt_cantbereserved} );
    output_html_with_http_headers( $cgi, $cookie, $template->output );
    exit;
}

my $items = Koha::Items->search( { biblionumber => $biblionumber, } );
my $itemunbless = Koha::Plugins::Handler->run( { class => 'Koha::Plugin::Es::Xercode::SpecialReserves', method => 'get_reservebable_item', params => $items } );

if ( !$itemunbless ){
    $template->param( error => 1 );
    $template->param( msg => $$translations{txt_cantbereserved} );
    output_html_with_http_headers( $cgi, $cookie, $template->output );
    exit;
}

$template->param(
    txt_request  => $$translations{txt_request},
    bibliodata   => $bibliodata,
    biblionumber => $biblionumber,
    txt_button   => $$translations{txt_button},
    txt_comment  => $$translations{txt_comment},
);

if ( $op eq 'request' ){
    my $comment = $cgi->param('comment');
    $comment = HTML::Entities::encode($comment) if ( $comment );
    my $patron = Koha::Patrons->find( $borrowernumber );
    
    my $library = Koha::Libraries->find( { branchcode => $itemunbless->{homebranch} } );
    my $branch_email = $library->branchemail || C4::Context->preference('KohaAdminEmailAddress');

    my $tokens->{borrower} = $patron->unblessed();
    $tokens->{biblio} = $biblio->unblessed();
    $tokens->{items} = $itemunbless;

    my @texts;
    my @emails;

    push @texts, $$translations{txt_mailtextlib};
    push @texts, $$translations{txt_mailtextpatron};
    push @emails, $branch_email;
    push @emails, $tokens->{borrower}->{email};
    my $i = 0;

    foreach my $text (@texts){
        next unless $emails[$i];
        foreach my $key (keys %$tokens){
            foreach my $subkey (keys $tokens->{$key}){
                $text =~ s/<<$key\.$subkey>>/$tokens->{$key}->{$subkey}/g;
            }
        }
        my $letter->{content} = $text;
        if ( $text =~ /<SUBJECT>(.*)<END_SUBJECT>/s ) {
            $letter->{subject} = Encode::encode("UTF-8", $1);
            $letter->{subject} =~ s|\n?(.*)\n?|$1|;
            $letter->{content} =~ s/<SUBJECT>$letter->{subject}<END_SUBJECT>//;
        }
        $letter->{content} .= "<p>$comment</p>" if ( $comment );
        my $message = Koha::Email->new();
        my %mail  = $message->create_message_headers({
            to          => $emails[$i],
            from        => C4::Context->preference('KohaAdminEmailAddress'),
            subject     => Encode::encode( "UTF-8", "" . $letter->{subject} ),
            message     => _wrap_html( Encode::encode( "UTF-8", "" . $letter->{content} ),
                            Encode::encode( "UTF-8", "" . $letter->{subject} ) ),
            contenttype => 'text/html; charset="utf-8"',
        });

        unless ( Mail::Sendmail::sendmail(%mail) ) {
            carp "Error sending mail: $Mail::Sendmail::error\n";
            $template->param( error => 1 );
            $template->param( msg => $$translations{txt_cantsent} );
        } else {
            $template->param( SENT => "1" );
            $template->param( msg => $$translations{txt_sent} );
        }
        $i++;
    }
}

output_html_with_http_headers( $cgi, $cookie, $template->output );

sub _wrap_html {
    my ($content, $title) = @_;

    return <<EOS;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$title</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
$content
</body>
</html>
EOS
}