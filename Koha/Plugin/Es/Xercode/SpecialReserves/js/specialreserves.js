if ( $('body#opac-detail').length ){

    var lang = $('html').attr('lang');
    var biblionumber =  $('#catalogue_detail_biblio').data('biblionumber');
    $.getJSON( "/reserve/can-special-reserves.pl?biblionumber="+biblionumber+'&lang='+lang, function( data ) {
        if (data.result == 1){
            $('#action').append('<li><a class="specialreserve btn btn-link btn-lg" href="/specialreserve.pl?biblionumber='+biblionumber+'"><i class="fa fa-fw fa-bookmark" aria-hidden="true"></i> '+data.button_text+'</a></li>');
        }
    });
}
