# Plugin Special Reserves

This is a plugin for Koha that send an email to a library to reserve an item that cannot normally be reserved from the OPAC.

### Requirements

- Koha mininum version: 18.05

### Installation

Download the package file koha-plugin-special-reserves.kpz

Login to Koha Admin and go to the plugin screen

Upload Plugin

### HTTP Server Configuration

You have to add two ScriptAliases:

    ScriptAlias /canspecialreserve.pl "/path/to/Koha/Plugin/Es/Xercode/SpecialReserves/opac/can-special-reserves.pl"
    ScriptAlias /specialreserve.pl "/path/to/Koha/Plugin/Es/Xercode/SpecialReserves/opac/opac-special-reserves.pl"

into the OPAC Virtualhost

### Configuration

The plugin requires configuration prior to usage. To configure the plugin, select the "Actions" button listed by the plugin in the "Plugins" page, then select "Configure". Texts of the labels and buttons can be customized.

Item or Biblioitem configuration, in the form key.field = value where key is biblioitems or items, using the same fields from the database tables: This is the condition by which the special reserve button will be shown or not, for example items.homebranch=IPT

Error text when cannot be reserved Error text when an email cannot be sent Confirmation text when an email is sent Text of the mail message to the library Text of the mail message to the patron Request submission button text Text for the comment box

Then click "Save configuration"

### OPAC Usage

Once installed, the plugin can be used by navigating to a bibliographical detail and clicking the link and filling a form requesting the reservation of the item.

### Notes

The condition must be as specific as possible, because if two copies of the same bibliographic but from different libraries match, only the notification will be sent to one library.