var chem = new function()
{
    this.WEEKdays       = ['неділя', 'понеділок', 'вівторок', 'среда', 'четвер', 'п\'ятница', 'субота'];
    this.MONTHS         = ['Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень', 'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'];
    this.MONTHSshort    = ['Лют', 'Січ', 'Бер', 'Квіт', 'Трав', 'Черв', 'Лип', 'Серп', 'Вер', 'Жовт', 'Лист', 'Груд'];
    this._AJAX = false;
    this.dialog_conf =
    {
        'modal' :       true,
        'autoOpen' :    false,
        'draggable' :   true,
        'resizable' :   false,
        'minWidth' :    100,
        'minHeight' :   100,
        'width' :       400,
        'position' :    {my: "center", at: "center", of: window},
        'dialogClass' : 'dialog-simple',
        'closeOnEscape' : true,
        'close':        function(event, ui){ chem.close_it( $(this) ); }
    };

/*
$('.ui-dialog-content').dialog("option", "position", {my: "center", at: "center", of: window});
*/

    this.update_unread_messages = function()
    {
        var post = {};
            post['ajax']        = 1;
            post['action']      = 3;
            post['mod']         = 'chat';

        $.ajax({ data: post }).done(function( _r )
        {
            try{ _r = jQuery.parseJSON( _r ); }catch(err)
            {
                return false;
            }

            $('body').find('[data-unread]').attr( 'data-unread', parseInt( _r['unread'] ) );

            return false;
        });
    }

    this.single_open = function( obj )
    {
        if( obj.hasClass('dialog_action') ){ return false; }
        else
        {
            obj.addClass('dialog_action');
            setTimeout( function(){ obj.removeClass('dialog_action');  } , 300 );
        }
    }
    this.txt2json = function( _r )
    {
        try{ _r = jQuery.parseJSON( _r ); }catch(err){ chem.err( 'ERROR: '+err+"\n\n"+_r ); return false; }

        _r['error'] = parseInt(_r['error']);

        if( parseInt(_r['error'])>0 ){ chem.err( _r['error_text'] ); return false; }
        return _r;
    }

    this.animate_opacity = function( obj, text, dyration )
    {
        dyration = parseInt( dyration );
        if( !dyration || dyration < 100 ){ dyration = 2000; }

         obj.removeClass('dnone')
            .text( text )
            .stop()
            .css( {"opacity": 1} )
            .animate({ "opacity": 0.15}, dyration, function()
            {
                $(this)
                    .addClass('dnone')
                    .css( {"opacity": 1} )
                    .parents('.ui-dialog').trigger('resize');
            })
            .parents('.ui-dialog').trigger('resize');
    }

    this.inputmask = function( obj )
    {
        var mask = {};

            mask["autoUnmask"] = true;

        if( parseInt( obj.attr('data-mask_repeat') ) )
        {
            mask["repeat"] = parseInt( obj.attr('data-mask_repeat') );
        }

        if( obj.attr('data-mask_placeholder') )
        {
            mask["placeholder"] = obj.attr('data-mask_placeholder');
        }

        if( obj.attr('data-mask') )
        {
            mask["mask"] = obj.attr('data-mask');
        }

        if( parseInt(obj.attr('data-need_lenth')) )
        {
            mask["onincomplete"] = function()
            {
                if( $(this).val().length < 1 ){ return false; }
            };
        }
        obj.inputmask( mask );
    }

    this.init_datepicker = function( obj )
    {
        if( obj.attr('type') == 'date' ){ return false; }

        var maxdate = obj.attr( 'data-maxdate' );
            maxdate = maxdate?maxdate:0;

        var mindate = obj.attr( 'data-mindate' );
            mindate = mindate?mindate:'-1y';
        /*************************************/
        obj.datepicker(
        {
            "showOtherMonths":      true,
            "selectOtherMonths":    true,
            "changeYear":           false,
            "dateFormat":           'dd.mm.yy',
            "maxDate":              maxdate,
            "minDate":              mindate,
            "firstDay":             1
        });
        /*************************************/
    }
    this.init_mask = function( obj )
    {
        obj.mask( obj.attr('data-mask'),
        {
            placeholder: obj.attr('data-placeholder'),
            selectOnFocus: true,
            onComplete: function()
            {
                if( !obj.attr('data-checkfunc') ){ return false; }
                if( obj.attr('data-checkfunc').length < 5 ){ return false; }

                var fn = window;
                var func = obj.attr('data-checkfunc').toString().split( "." );

                for( var i = 0; func.length; i++ )
                {
                    if (typeof fn === "object" ){ fn = fn[func[i]]; }
                    if (typeof fn === "function"){ break; }
                    if ( i > 10 ){ return false; }
                }

                if (typeof fn === "function"){ fn( obj ); }
            },
            translation:
            {
                'A': { pattern: /[0-2]/, optional: true },
                'B': { pattern: /[0-3]/, optional: true },
                'C': { pattern: /[0-5]/, optional: true },
                'X': { pattern: /[0-9]/, optional: true }
            }
        });
    }

    this.GoToUrl = function( url )
    {
        window.location.href = url;
    }

    this.close_it = function( obj )
    {
        if( obj.dialog( "isOpen" ) || obj.hasClass('ui-dialog-content') ){ obj.dialog("close").dialog("destroy").remove(); }
        obj.remove();
    }

    this.BL_RED = function( obj, steps )
    {
        if( steps == undefined ){ steps = 9; }
        steps = parseInt( steps );

        if( obj.hasClass( 'blred') )
            { obj.removeClass( 'blred') }
        else
            { obj.addClass( 'blred') }

        steps = steps - 1;
        if( steps > 1 )
        {
            setTimeout( function(){ chem.BL_RED( obj, steps ); } , 200 );
        }
    }

    this.BL = function( obj, stop, classname )
    {
        if( !obj.hasClass('warn') ){ obj.addClass('warn'); }

        stop = parseInt( stop );
        stop = stop?stop:5;
        classname = classname?classname:'blred';
        
        if( stop == 1 )
        {
            obj.removeClass('warn');
            obj.removeClass(classname);
            return false;
        }

        if( obj.hasClass(classname) ){ obj.removeClass(classname); }
        else{ obj.addClass(classname); }

        if( stop > 0 ){ setTimeout( function(){ chem.BL( obj, --stop, classname ); } , 500); }
    }

    this.init_checkbox = function( obj )
    {
        if( parseInt(obj.attr('data-value')) == 1 ){ obj.prop('checked', true ); }
        else{ obj.prop('checked', false ); }
    }

    this.init_select = function( obj )
    {
        var id = obj.attr('data-value');
        obj.find('option').attr( 'selected', false );
        obj.find('option[value="'+id+'"]').attr( 'selected', 'selected' );
    }

    this.err = function( txt, title )
    {
        $('#err .title').text( title?title:'Помилка!' );
        $('#err .message pre').text( txt );
        $('#err').show();
    };

    this.clear_cache = function()
    {
        var post = {};
            post['ajax'] = 1;
            post['mod'] = 'clean_cache';

        $.ajax({ data: post }).done(function( _r )
        {
            var color = $('#foot span').css('color');
            $('#foot span')  .css("color", "#2BD600")
                        .stop()
                        .animate( { "color": color }, 1300 );
        });
    }



}

//////////////////////////////////////////////////////////////////////////////////////////

var sort = new function()
{
    this.STILL_SORT = false;

    this.renum = function( obj )
    {
        if( obj.hasClass('stats_table') )
        {
            obj.find('tbody').each( function()
            {
                var i = $(this).find( 'tr.data' ).length;

                $(this).find( 'tr.data' ).each(function()
                {
                    $(this).find('.numi').text( i );
                    i = i - 1;
                });

            } );
        }
        else
        {
            obj = obj.find( '.line' );
            var i = obj.length;

            obj.each(function()
            {
                $(this).find('.numi').text( i );
                i = i - 1;
            });
        }



    }
    this.init = function( obj )
    {
        var sorter_name = obj.attr( 'data-sort' );
        var sorter_type = obj.attr( 'data-type' );

        var list = obj.parents('#list_frame').find('#list');
        var find = 'line';

        if( obj.parents('#list_frame').hasClass('stats') )
        {
            list = obj.parents('table');
            find = 'data';
        }


        if( sort.STILL_SORT )
        {
            return false;
        }
        sort.STILL_SORT = true;
        ///////////////////////////////////

        if( !sorter_name )
        {
            sort.STILL_SORT = false;
            return false;
        }

        ///////////////////////////////////

        var direction = obj.attr( 'data-direction' );
        if( !direction )
        {
            direction = 'asc';
        }
        else
        {
            if( direction == 'asc' ){ direction = 'desc'; }
            else                    { direction = 'asc';  }
        }
        obj.attr( 'data-direction', direction );

        ///////////////////////////////////

        $('[data-sorter="1"]').removeClass('active');
        obj.addClass('active');

        ///////////////////////////////////

        list.find( '.' + find ).sort(function(a,b)
        {
            sort.STILL_SORT = true;

            var _a = $(a).find('[data-role="sort"][name="'+sorter_name+'"]').val();
            var _b = $(b).find('[data-role="sort"][name="'+sorter_name+'"]').val();

            if( sorter_type == 'txt' )
            {
                if( direction == 'asc' )
                {
                    return _a.localeCompare( _b );
                }
                else
                {
                    return _b.localeCompare( _a );
                }
            }

            if( sorter_type == 'int' )
            {
                _a = parseFloat( _a );
                _b = parseFloat( _b );

                if( _a == _b )
                {
                    return 0;
                }
                if( _a > _b )
                {
                    if( direction == 'asc' ){ return 1; }else{ return -1; }
                }
                else
                {
                    if( direction == 'asc' ){ return -1; }else{ return 1; }
                }
                return 0;
            }


        }).detach().appendTo( list );

        sort.renum( list );

        sort.STILL_SORT = false;
    }
}

//////////////////////////////////////////////////////////////////////////////////////////

$(document).ready( function()
{
    var CURR_REGION = parseInt( $('body').attr( 'data-region_id' ) );
    /////////////////////////////////////////////////////////////////////////
    $.ajaxSetup({
        "url":          '/index.php',
        "global":       false,
        "crossDomain":  false,
        "type":         "POST",
        "dataType":     "text",
        "async":        true,
        "cache":        false,
        "timeout":      false,
        "beforeSend":   function( jqXHR, settings )
                                        {
                                            jqXHR['uniq'] = Math.floor((Math.random() * 1000000) + 1);
                                            console.time("AJAX UNIQ_ID: "+jqXHR['uniq']);
                                            console.log( 'AJAX UNIQ_ID: '+jqXHR['uniq']+' '+settings.type+' to: ' + settings.url + '?' + settings.data );
                                            chem._AJAX = true;
                                        },
        "complete":     function( jqXHR, textStatus)
                                        {
                                            console.log( 'AJAX UNIQ_ID: '+jqXHR['uniq']+' finished with status: ' + jqXHR.status );
                                            console.timeEnd("AJAX UNIQ_ID: "+jqXHR['uniq']);
                                            chem._AJAX = false;
                                        },
        "error":        function( jqXHRo, err_type ){ alert( 'AJAX ERROR: '+err_type ); }
    });
    /////////////////////////////////////////////////////////////////////////

    $('[data-mask]').each(function()        { chem.init_mask( $(this) ); });
    $('input[name*="date"][type="text"]').each(function(){ chem.init_datepicker( $(this) ); });
    $('select[data-value]').each(function() { chem.init_select( $(this) ); });

    /////////////////////////////////////////////////////////////////////////

    $('[data-sorter="1"]').on('click', function(){ sort.init( $(this) ); });

    $('#filters input[type="checkbox"][data-group]').on('change', function()
    {
        var is_ch = $(this).is(':checked');
        $('#filters input[type="checkbox"][data-group="'+$(this).attr('data-group')+'"]').prop( 'checked', false );
        $(this).prop( 'checked', is_ch );
    });

    /////////////////////////////////////////////////////////////////////////

    $('[data-role^="dialog:window"]').dialog( chem.dialog_conf );

    /////////////////////////////////////////////////////////////////////////

    $( "body" ).on( "dialogcreate", function( event, ui ){ console.log( 'DIALOG CREATED: id='+event['target']['id'] ); } );
    $( "body" ).on( "dialogclose",  function( event, ui ){ console.log( 'DIALOG CLOSED: id='+event['target']['id'] ); } );

    $(window).on( "dialogopen", function( event, ui )
    {

    } );

    $(window).resize(function()
    {
        $('.ui-dialog-content').dialog("option", "position", {my: "center", at: "center", of: window});
    });

    $( '#foot .foot_logo_name' ).click( function()
    {
        chem.clear_cache();
    } );

    $('[data-role="show_or_hide"][data-content_id]').click(function()
    {
        var obj = $('#'+$(this).attr( 'data-content_id' ));

        if( obj.hasClass( 'dnone' ) ){ obj.removeClass('dnone'); }
        else{ obj.addClass('dnone'); }
    });

    if( parseInt( $('body').attr('data-allow_chat') ) > 0 )
    {
        setInterval( function(){ chem.update_unread_messages() }, 15000);
    }








































});

