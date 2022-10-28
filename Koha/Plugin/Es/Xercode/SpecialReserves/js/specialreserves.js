if ( $('body#opac-detail').length ){

    var lang = $('html').attr('lang');
    var biblionumber =  $('#catalogue_detail_biblio').data('biblionumber');
    $.getJSON( "/canspecialreserve.pl?biblionumber="+biblionumber+'&lang='+lang, function( data ) {
        if (data.result == 1){
            $('#action').append('<li><a class="specialreserve btn btn-link btn-lg" href="/specialreserve.pl?biblionumber='+biblionumber+'"><i class="fa fa-fw fa-bookmark" aria-hidden="true"></i> Place Special hold</a></li>');
        }
    });
}