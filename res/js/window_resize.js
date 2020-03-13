$(document).ready( function()
{
    $('#main_frame').height(  $(window).height() );

    $(window).resize(function()
    {
        $('.ui-dialog-content').dialog("option", "position", {my: "center", at: "center", of: window});
        $('#main_frame').height( $(window).height() );
    });

    $('#err .close').on( "click", function(){ $('#err').hide(); } );
});