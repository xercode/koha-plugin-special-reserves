package Koha::Plugin::Es::Xercode::SpecialReserves;

use Modern::Perl;

use base qw(Koha::Plugins::Base);

use Koha::DateUtils qw( dt_from_string );
use C4::Context;
use C4::Auth;
use Carp;

our $VERSION = "1.2.3";

our $metadata = {
    name            => 'Special Reserves',
    author          => 'Xercode',
    date_authored   => '2019-06-14',
    date_updated    => "2019-10-07",
    minimum_version => '17.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin provides a special reserve on a particular bibliografic record'
};

sub new {
    my ( $class, $args ) = @_;

    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool {
    my ( $self ) = @_;
    my $cgi = $self->{'cgi'};
    $self->configure();
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            enable_special_reserves => $self->retrieve_data('enable_special_reserves'),
            last_upgraded           => $self->retrieve_data('last_upgraded'),
            key_value               => $self->retrieve_data('key_value'),
            txt_cantbereserved      => $self->retrieve_data('txt_cantbereserved'),
            txt_cantsent            => $self->retrieve_data('txt_cantsent'),
            txt_mailtextlib         => $self->retrieve_data('txt_mailtextlib'),
            txt_sent                => $self->retrieve_data('txt_sent'),
            txt_button              => $self->retrieve_data('txt_button'),
            txt_request             => $self->retrieve_data('txt_request'),
            txt_comment             => $self->retrieve_data('txt_comment'),
            txt_mailtextpatron      => $self->retrieve_data('txt_mailtextpatron'),
        );

        $self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                enable_special_reserves => $cgi->param('enable_special_reserves'),
                last_configured_by      => C4::Context->userenv->{'number'},
                key_value               => $cgi->param('key_value'),
                txt_cantbereserved      => $cgi->param('txt_cantbereserved'),
                txt_cantsent            => $cgi->param('txt_cantsent'),
                txt_mailtextlib         => $cgi->param('txt_mailtextlib'),
                txt_sent                => $cgi->param('txt_sent'),
                txt_button              => $cgi->param('txt_button'),
                txt_request             => $cgi->param('txt_request'),
                txt_comment             => $cgi->param('txt_comment'),
                txt_mailtextpatron      => $cgi->param('txt_mailtextpatron'),
            }
        );
        $self->go_home();
    }
}

sub install() {
    my ( $self, $args ) = @_;

    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

    return 1;
}

sub uninstall() {
    my ( $self, $args ) = @_;
}

sub opac_special_reserves {
    my ( $self, $args ) = @_;

    return $self->retrieve_data('enable_special_reserves') eq 'Yes';
}

sub get_key_value {
    my ( $self, $args ) = @_;
    my $dbh = C4::Context->dbh;

    my $pluginvalue = $self->retrieve_data('key_value');
    if ( $pluginvalue !~ m/(^\w{5,}\.\w{1,}\=\w{1,})/){
        carp($self->{class}." - Error in key value format");
        return;
    }

    my %keyvalue;
    my ($bothKeys,$value)= split(/=/, $pluginvalue);
    my ($key,$subkey) = split(/\./,$bothKeys);
    %keyvalue = (
        key    => $key,
        subkey => $subkey,
        value  => $value,
        );

    return \%keyvalue;
}

sub get_text_labels {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;
    my $query = "
        SELECT plugin_key,plugin_value FROM plugin_data
            WHERE plugin_class = ?
            AND plugin_key like 'txt_%'
    ";

    my $sth = $dbh->prepare($query);
    $sth->execute($self->{class});

    my $txtValues = $sth->fetchall_arrayref({});
    my %translations;
    foreach my $text (@{$txtValues}){
        $translations{$text->{plugin_key}} = $text->{plugin_value};
    }

    return \%translations;
}

sub can_be_reserved {
    my ( $self, $args ) = @_;

    my $keyvalue = $self->get_key_value();
    return 0 unless ( $keyvalue );

    my $subkey = $keyvalue->{subkey};
    my $value = $keyvalue->{value};

    my $bibliodata = $args->unblessed();

    if ( $keyvalue->{key} eq 'biblioitems' ){
        if ( $bibliodata->{$subkey} eq $value ){
            return 1;
        }
    } elsif ( $keyvalue->{key} eq 'items' ) {
        my $items = Koha::Items->search( { biblionumber => $bibliodata->{biblionumber}, } );
        while ( my $item = $items->next() ) {
            my $itemdata = $item->unblessed();
            if ( $itemdata->{$subkey} eq $value ){
                return 1;
            }
        }
    }

    return 0;
}

sub get_reservebable_item {
    my ( $self, $items ) = @_;

    my $keyvalue = $self->get_key_value();
    return 0 unless ( $keyvalue );

    my $subkey = $keyvalue->{subkey};
    my $value = $keyvalue->{value};

    if ( $keyvalue->{key} eq 'items' ) {
        while ( my $item = $items->next() ) {
            my $itemdata = $item->unblessed();
            if ( $itemdata->{$subkey} eq $value ){
                return $itemdata;
            }
        }
    }

    return 0;
}

1;
