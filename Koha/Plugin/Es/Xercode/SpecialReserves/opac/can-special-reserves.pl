#!/usr/bin/perl

use lib $ENV{PERL5LIB};
use C4::Context;
use lib C4::Context->config("pluginsdir");
use Koha::Plugin::Es::Xercode::SpecialReserves;
use JSON;
use Data::Dumper;
use CGI;
use Koha::Biblios;

my $cgi = new CGI;
my $plugin = Koha::Plugin::Es::Xercode::SpecialReserves->new();
my $userid = C4::Context->userenv ? C4::Context->userenv->{id} : undef;
my $biblionumber = $cgi->param('biblionumber');
my $lang = $cgi->param('lang');

print $cgi->header( -type => 'application/json', -charset => 'utf-8' );
if ($biblionumber =~ /^[0-9]+$/){
	my ($status, $button_text) = $plugin->_GetStatus($biblionumber, $lang);
	print to_json({'result' => $status, 'button_text' => $button_text});
}else{
	print to_json({'result' => "0"});
}
