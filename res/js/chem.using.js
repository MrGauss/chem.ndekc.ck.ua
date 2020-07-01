chem['using'] = new function()
{
    this.check_before_save = function( obj )
    {
        var did = obj.attr('id');
        var err = 0;

        obj.find('input[data-important="1"]').each( function()
        {
            if( $(this).val() == '' )
            {
                chem.BL( $(this), 5, 'blred' );
                err = 1;
            }
        } );

        obj.find('select[data-important="1"]').each( function()
        {
            if( parseInt( $(this).val() ) == 0 )
            {
                chem.BL( $(this), 5, 'blred' );
                err = 1;
            }
        } );

        if( err ){ return false; }
        else{ return true; }
    }

    this.reload = function( line_hash )
    {
        line_hash = line_hash ? line_hash : '';

        var post = {};
            post['ajax']        = 1;
            post['action']      = 4;
            post['subaction']   = 1;
            post['mod']         = $('body').attr('data-mod');
            post['filters']     = {};

        $('#filters').find('[data-role="filter"]').each(function(){ post['filters'][$(this).attr('name')] = $(this).val(); });

        if( line_hash != '' ){ post['filters']['hash'] = line_hash; }

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );

            if( _r['lines'] )
            {
                if( line_hash != '' )
                {
                    $('#content #list_frame .list .line[data-hash="'+line_hash+'"]')
                        .off()
                        .replaceWith( _r['lines'] );

                    $('#content #list_frame .list .line[data-hash="'+line_hash+'"]')
                        .off()
                        .on( "click", function(){ chem.using.editor( $(this) ); })
                        .addClass('blink')
                        .switchClass( 'blink', 'normal', 1000, 'swing', function()
                        {
                            $(this)
                                .removeClass('blink')
                                .removeClass('normal');
                        } );
                }
                else
                {
                    $('#content #list_frame .list .line[data-hash]').off().remove();
                    $('#content #list_frame .list').append( _r['lines'] );
                    $('#content #list_frame [data-hash]')
                        .off()
                        .on( "click", function(){ chem.using.editor( $(this) ); })
                        .addClass('blink')
                        .switchClass( 'blink', 'normal', 1000, 'swing', function()
                        {
                            $(this)
                                .removeClass('blink')
                                .removeClass('normal');
                        } );
                }
            }
        });

    }

    this.add_to_list = function( obj )
    {
        var empty = obj.parents( '[data-role="dialog:window"]' ).find('[id="' + obj.parent().attr( 'data-empty' ) + '"] .consume');

        obj
            .removeClass('dnone')
            .addClass( 'dnone' );

        empty.attr( 'data-consume_hash', '' );
        empty.attr( 'data-reactiv_hash', obj.attr('data-hash') );
        empty.attr( 'data-dispersion_id', obj.attr('data-id') );
        empty.attr( 'data-key', '' );

        empty.find('.reagent_name').html(               obj.find('.name').html() );
        empty.find('.reagent_number').html(             obj.find('.number').html() );
        empty.find('.cooked_dead_date').html(           obj.find('.dead_date b').html() );

        empty.find('[name="consume_quantity"]').attr('max', obj.attr('data-quantity_left') ).attr( 'value', '0' ).val( '0' );
        empty.find('[name="units_short_name"]').attr( 'value', obj.attr('data-units') ).val( obj.attr('data-units') );

        empty
            .clone()
            .appendTo( obj.parents('.side').find( '.listline' ) );

        obj.parents('.side').find( '.listline .consume .remove' )
            .off()
            .on( 'click', function()
            {
                var parent = $(this).parent();

                $(this).parents('.side').find('.selectable_list [data-id="' + parent.attr('data-dispersion_id') + '"]').removeClass( 'dnone' );
                $(this).parents('.side').find('.selectable_list [data-hash="' + parent.attr('data-reactiv_hash') + '"]').removeClass( 'dnone' );

                $(this).parent().remove();
            } );

            /*.find( '[data-role="button"]' )
            .on('click',function()
            {
                var p = $(this).parents('.reagent');
                var d = $(this).parents('.default_editor');
                d.find( '#ingridients [data-dispersion_id="' + p.attr( 'data-dispersion_id' ) + '"]' ).removeClass( 'dnone' );
                p.remove();
            })
            .parents('.reagent')
            .find( '[name="quantity"]' )
            .off()
            .on( 'change', function()
            {
                //chem.cooked.check_input_quantity(  );
            });  */

    }

    this.editor = function( obj )
    {
        chem.single_open( obj );

        var line_hash = obj.attr('data-hash');
        var did_pref = 'using-edit-form';
        var did = did_pref + '-' + line_hash + '-' + Math.floor((Math.random() * 1000000) + 1);

        chem.close_it( $('[id*="'+did_pref+'"]') );

        var post = {};
            post['ajax'] = 1;
            post['action'] = 1;
            post['subaction'] = 1;
            post['mod']     = $('body').attr('data-mod');
            post['hash']    = line_hash;
            post['rand']    = Math.floor((Math.random() * 1000000) + 1);

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            if( _r['form'] )
            {
                $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="Облік витрат: '+(line_hash?'редагування запису':'створення запису')+'">'+_r['form']+'</div>' );

                autocomplete.init( $('#'+did+'') );

                $('#'+did+'').find('input[name="search"]').on('keyup', function()
                {
                    var st = $(this).val().toLowerCase();
                    if( st.length < 3 )
                    {
                        $('#'+did+' .selectable_list .line').removeClass( 'dnone' );
                    }
                    else
                    {
                        $('#'+did+' .selectable_list .line').addClass( 'dnone' );
                        $('#'+did+' .selectable_list .line[data-name*="'+st+'"]').removeClass( 'dnone' );
                    }



                });


                $('#'+did+'').find('select[name="purpose_id"]').on('change', function()
                {
                    $('#'+did).find('.elem[data-purpose]')
                        .removeClass('dnone')
                        .addClass('dnone')
                        .find('.input')
                        .each( function()
                        {
                            $(this).attr( 'data-save', false );
                            $(this).attr( 'data-important', false );
                        } );


                    $('#'+did).find('.elem[data-purpose~="'+$(this).find('option:selected').attr( 'data-attr' )+'"]')
                        .removeClass('dnone')
                        .find('.input')
                        .each( function()
                        {
                            $(this).attr( 'data-save', '1' );
                            if( !$(this).hasClass('noimportant') ){ $(this).attr( 'data-important', '1' ) }
                        } );

                }).trigger( "change" );

                $('#'+did+'').find('select[data-value]')    .each(function(){ $(this).val( $(this).attr('data-value') ).trigger( "change" ); });
                $('#'+did+'').find('input[name*="date"]')   .each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]')                   .each(function(){ chem.init_mask( $(this) ); });


                $('#'+did+' .listline .consume').each(function()
                {
                    $(this)
                        .parents('.side')
                        .find('.selectable_list [data-id="' + $(this).attr('data-dispersion_id') + '"]')
                        .removeClass( 'dnone' )
                        .addClass( 'dnone' );

                    $(this)
                        .parents('.side')
                        .find('.selectable_list [data-hash="' + $(this).attr('data-reactiv_hash') + '"]')
                        .removeClass( 'dnone' )
                        .addClass( 'dnone' );
                });

                $('#'+did+' .selectable_list .line').on( "click", function( event, ui )
                {
                    chem.using.add_to_list( $(this) );
                });

                if( line_hash != '' )   { $('#'+did).find('select[name="purpose_id"]').attr( 'disabled', 'disabled' ); }
                else                    { $('#'+did).find('select[name="purpose_id"] option[data-attr="reactiv"]').css( 'display', 'none' );     }

                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]  = 2001;
                    dialog["modal"]   = true;
                    dialog["autoOpen"]   = true;
                    dialog["width"]   = '900';
                    dialog["resizable"]   = false;
                    dialog["buttons"] = {};

                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = "Скасувати";
                    dialog["buttons"][bi]["click"] = function(){ chem.close_it( $('#'+did) ); };
                    dialog["buttons"][bi]["class"] = "type1";
                    dialog["buttons"][bi]["data-role"] = "close_button";
                    bi++;

                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = "Зберегти";
                    dialog["buttons"][bi]["click"] = function()
                    {
                        if( !$('#'+did+' .error_area').hasClass('dnone') ){ $('#'+did+' .error_area').addClass('dnone'); }

                        if( chem.using.check_before_save( $('#'+did) ) )
                        {
                            var post = {};
                                post['ajax'] = 1;
                                post['action'] = 2;
                                post['subaction'] = 1;
                                post['mod']         = $('body').attr('data-mod');
                                post['rand']        = Math.floor((Math.random() * 1000000) + 1);
                                post['hash']        = $('#'+did).find('input[name="hash"]').val();
                                post['key']         = $('#'+did).find('input[name="key"]').val();
                                post['save']        = {};

                            $( '#'+did ).find( '[data-save="1"]' ).each( function()
                            {
                                post['save'][$(this).attr('name').toString()] = $(this).val().toString();
                            } );

                            /////////////////

                            post['save']['consume'] = new Array();
                            $('#'+did).find('#consume_list .consume').each(function()
                            {
                                post['save']['consume'].push
                                (
                                    {
                                        'key':              $(this).attr('data-key'),
                                        'consume_hash':     $(this).attr('data-consume_hash'),
                                        'dispersion_id':    $(this).attr('data-dispersion_id'),
                                        'quantity':         $(this).find('input[name="consume_quantity"]').val()
                                    }
                                );
                            });

                            post['save']['reactiv_consume'] = new Array();
                            $('#'+did).find('#reactiv_consume_list .consume').each(function()
                            {
                                post['save']['reactiv_consume'].push
                                (
                                    {
                                        'key':              $(this).attr('data-key'),
                                        'consume_hash':     $(this).attr('data-consume_hash'),
                                        'reactiv_hash':     $(this).attr('data-reactiv_hash'),
                                        'quantity':         $(this).find('input[name="consume_quantity"]').val()
                                    }
                                );
                            });

                            /////////////////

                            $.ajax({ data: post }).done(function( _r )
                            {
                                try{ _r = jQuery.parseJSON( _r ); }catch(err){ chem.err( 'ERROR: '+err+"\n\n"+_r ); return false; }

                                _r['error'] = parseInt(_r['error']);
                                _r['hash'] = _r['hash'];

                                if( parseInt(_r['error'])>0 )
                                {
                                    chem.animate_opacity( $('#'+did+' .error_area'), _r['error_text'], 3000 );

                                    if( _r['err_area'] )
                                    {
                                        _r['err_area'] = _r['err_area'].toString().split ( '|'.toString() );

                                        $.each( _r['err_area'], function( index, value )
                                        {
                                            chem.BL( $('#'+did+'').find('[name="'+value+'"]'), 15, 'blred' );
                                        } );
                                    }
                                }
                                else
                                {
                                    if( !line_hash || line_hash != _r['hash'] )
                                    {
                                        setTimeout( function(){ chem.close_it( $('#'+did) ); } , 1 );
                                        setTimeout( function(){ chem.using.reload(); } , 2 );
                                    }
                                    else
                                    {
                                        if( _r['hash'] != '' )
                                        {

                                            setTimeout( function(){ chem.using.reload( _r['hash'] ); } , 1 );
                                            setTimeout( function(){ chem.close_it( $('#'+did) ); } , 2 );
                                            setTimeout( function(){ $('#content #list_frame [data-hash="'+_r['hash']+'"]').trigger( "click" ); } , 3 );
                                        }
                                    }
                                }
                            });
                        }

                    };

                    dialog["buttons"][bi]["class"] = "type2";
                    dialog["buttons"][bi]["data-role"] = "close_button";
                    bi++;

                    if( line_hash != '' )
                    {
                        dialog["buttons"][bi] = {};
                        dialog["buttons"][bi]["text"]  = "Видалити";
                        dialog["buttons"][bi]["click"] = function()
                        {
                            var post = {};
                                post['ajax'] = 1;
                                post['action'] = 3;
                                post['subaction'] = 1;
                                post['mod']         = $('body').attr('data-mod');
                                post['hash']        = $('#'+did).find('input[name="hash"]').val();
                                post['key']         = $('#'+did).find('input[name="key"]').val();
                                post['rand']        = Math.floor((Math.random() * 1000000) + 1);

                            $.ajax({ data: post }).done(function( _r )
                            {
                                _r = chem.txt2json( _r );

                                if( _r['hash'] != '' )
                                {
                                    $('#list .line[data-hash="'+_r['hash']+'"]').remove();
                                    chem.close_it( $('#'+did) );

                                    chem.using.reload();
                                }
                            });
                        };
                        dialog["buttons"][bi]["class"] = "type5 right";
                        dialog["buttons"][bi]["data-role"] = "delete_button";
                        bi++;
                    }


                $('#'+did)
                    .dialog( dialog )
                    .find('input[name="search"]').focus();
            }
        });
    }

    this.mase_search = function()
    {

    }
    this.init = function()
    {
        $('#content #list_frame [data-hash]').on( "click", function()
        {
            chem.using.editor( $(this) );
        });

        $('#content #list_frame #filters #search').on( "click", function()
        {
            chem.using.reload();
        });
    }
}

$(document).ready( function()
{
    chem.using.init();
});