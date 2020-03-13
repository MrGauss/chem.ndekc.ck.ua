$(document).ready( function()
{
       $('#content #color_changer input').on( "input", function()
        {
            $('#shkurdoda_frame_mask').css('filter', 'hue-rotate('+$(this).val()+'deg)');
        });
});