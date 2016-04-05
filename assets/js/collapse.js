$(document).ready(function () {
    $('.collapse').hide();
    $('h3').click(function () {
        $(this).toggleClass("open");
        $(this).next().toggle();
    }); //end toggle

    $('#expandall').click(function () {
        $('.collapse').show();
        $('h3').addClass("open");
    });

    $('#collapseall').click(function () {
        $('.collapse').hide();
        $('h3').removeClass("open");
    });

}); //end ready
