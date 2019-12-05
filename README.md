# Koha-Plugin-Es-Xercode-SpecialReserves

This is a plugin for Koha that send an email to a library to reserve an item that cannot normally be reserved from the OPAC.

### Getting Started
Download this plugin by downloading the latest release .kpz file from the release page.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

Change <enable_plugins>0<enable_plugins> to <enable_plugins>1</enable_plugins> in your koha-conf.xml file Confirm that the path to <pluginsdir> exists, 
is correct, and is writable by the web server. Restart your webserver. Once set up is complete you will need to alter your UseKohaPlugins system preference. 
Finally, on the "Koha Administration" page you will see the "Manage Plugins" option, select this to access the Plugins page.

### Installing

Add in opac-detail-sidebar.inc before the closing tag of the ul:

    [% FOREACH p IN plugins %]
        [% IF ( p.can_be_reserved(biblio) ) %]
            <li><a class='reserve' href='/reserve/opac-special-reserves.pl?biblionumber=[% biblio.biblionumber %]'>Place Special hold</a></li>
        [% END %]
    [% END %]

Add in opac/opac-detail.pl, opac/opac-ISBDdetail.pl, opac/opac-MARCdetail.pl and opac/opac-account.pl

    use Koha::Plugins;

    And before the output_html_with_http_headers

        my $plugins_enabled = C4::Context->preference('UseKohaPlugins') && C4::Context->config("enable_plugins");
        if ( $plugins_enabled ) {
            my @plugins = Koha::Plugins->new()->GetPlugins({
            method => 'opac_special_reserves',
            });
            @plugins = grep { $_->opac_special_reserves } @plugins;
            $template->param( plugins => \@plugins );
        }

Install the plugin selecting the "Upload plugin" button on the Plugins page and navigating to the .kpz file you downloaded

### Configuration
The plugin requires configuration prior to usage. To configure the plugin, select the "Actions" button listed by the plugin in the "Plugins" page, then select "Configure". Texts of the labels and buttons can be customized.

Item or Biblioitem configuration, in the form key.field = value where key is biblioitems or items, using the same fields from the database tables: 
  This is the condition by which the special reserve button will be shown or not, for example items.homebranch=IPT

Error text when cannot be reserved
Error text when an email cannot be sent
Confirmation text when an email is sent
Text of the mail message to the library
Text of the mail message to the patron
Request submission button text
Text for the comment box

Then click "Save configuration"

### Usage
Once installed, the plugin can be used by navigating to a bibliographical detail and clicking the link and filling a form requesting the reservation of the item.

### Notes
The condition must be as specific as possible, because if two copies of the same bibliographic but from different libraries match, only the notification will be sent to one library.

### Authors
Xercode