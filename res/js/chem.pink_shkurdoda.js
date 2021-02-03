$(document).ready( function()
{
       $('#content #color_changer input[type="range"]').on( "input", function()
        {
            var filters = new Array();
            $(this)
                .parents('#color_changer')
                .find('input[type="range"].layer2')
                .each(function()
                {
                    var en = '';
                    var name = $(this).attr('name');

                    if( $(this).attr('name') == 'hue-rotate' )  { en = 'deg'; }
                    if( $(this).attr('name') == 'saturate' )    { en = '%'; }
                    if( $(this).attr('name') == 'brightness' )  { en = '%'; }

                    filters.push( $(this).attr('name')+'('+$(this).val()+en+')' );
                });

            filters = filters.join(' ');
            $('#shkurdoda_frame_mask').css('filter', filters );

            filters = new Array();
            $(this)
                .parents('#color_changer')
                .find('input[type="range"].layer3')
                .each(function()
                {
                    var en = '';
                    var name = $(this).attr('name');

                    if( $(this).attr('name') == 'hue-rotate' )  { en = 'deg'; }
                    if( $(this).attr('name') == 'saturate' )    { en = '%'; }
                    if( $(this).attr('name') == 'brightness' )  { en = '%'; }

                    filters.push( $(this).attr('name')+'('+$(this).val()+en+')' );
                });

            filters = filters.join(' ');
            $('#shkurdoda_frame_mask2').css('filter', filters );
        });


});