chem['using'] = new function()
{
    this._ADD_TRIGGER_ACTIVE = false;

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
            else
            {
                $('#content #list_frame .list .line[data-hash]').off().remove();
            }
        });

    }

    this.check_quantity = function( obj )
    {
        var max = parseInt( obj.attr( 'max' ) );
        var val = parseInt( obj.val() );

        if( val > max )
        {
            obj.removeClass( 'error' ).addClass( 'error' );
        }
        else
        {
            obj.removeClass( 'error' );
        }
    }

    this.add_to_list = function( obj )
    {
        chem.using._ADD_TRIGGER_ACTIVE = true;

        var empty = obj.parents( '[data-role="dialog:window"]' ).find('[id="' + obj.parent().attr( 'data-empty' ) + '"] .consume');

        obj
            .removeClass('dnone')
            .addClass( 'dnone' );

        empty.attr( 'data-consume_hash',    '' );
        empty.attr( 'data-reactiv_hash',    obj.attr('data-hash') );
        empty.attr( 'data-dispersion_id',   obj.attr('data-id') );
        empty.attr( 'data-key',             '' );

        empty.find('.reagent_name').html(               obj.find('.name').html() );
        empty.find('.reagent_number').html(             obj.find('.number').html() );
        empty.find('.cooked_dead_date').html(           obj.find('.dead_date b').html() );

        empty.find('[name="consume_quantity"]').attr('max', obj.attr('data-quantity_left') ).attr( 'value', '0' ).val( '0' );
        empty.find('[name="units_short_name"]').attr( 'value', obj.attr('data-units') ).val( obj.attr('data-units') );

        // data-err_area

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



        obj.parents('.side').find( '.listline .consume input[name="consume_quantity"]' ).off()
            .change(function(){ chem.using.check_quantity( $(this) ); })
            .on('keyup',function(){ chem.using.check_quantity( $(this) ); });

        chem.using._ADD_TRIGGER_ACTIVE = false;

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
                $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="���� ������: '+(line_hash?'����������� ������':'��������� ������')+'">'+_r['form']+'</div>' );

                autocomplete.init( $('#'+did+'') );

                $('#'+did).find( '.listline .consume input[name="consume_quantity"]' ).off()
                    .change(function(){ chem.using.check_quantity( $(this) ); })
                    .on('keyup',function(){ chem.using.check_quantity( $(this) ); });

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
                    dialog["buttons"][bi]["text"]  = "���������";
                    dialog["buttons"][bi]["click"] = function(){ chem.close_it( $('#'+did) ); };
                    dialog["buttons"][bi]["class"] = "type1";
                    dialog["buttons"][bi]["data-role"] = "close_button";
                    bi++;

                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = "��������";
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
                                    chem.animate_opacity( $('#'+did+' .error_area'), _r['error_text'], 4000 );

                                    if( _r['err_area'] )
                                    {
                                        _r['err_area'] = _r['err_area'].toString().split ( '|'.toString() );

                                        $.each( _r['err_area'], function( index, value )
                                        {
                                            if( value.indexOf( 'reagent:' ) !== -1 )
                                            {
                                                value = value.replace( 'reagent:', '' );
                                                chem.BL( $('#'+did+' #consume_list').find('[data-dispersion_id="'+value+'"]').stop(), 15, 'blred' );
                                            }
                                            else
                                            if( value.indexOf( 'reactiv:' ) !== -1 )
                                            {
                                                value = value.replace( 'reactiv:', '' );
                                                chem.BL( $('#'+did+' #reactiv_consume_list').find('[data-reactiv_hash="'+value+'"]').stop(), 15, 'blred' );
                                            }
                                            else
                                            {
                                                chem.BL( $('#'+did+'').find('[name="'+value+'"]'), 15, 'blred' );
                                            }
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

                                            setTimeout( function(){ chem.using.reload(); } , 1 );  /// setTimeout( function(){ chem.using.reload( _r['hash'] ); } , 1 );
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

                    /////////////////////////////////////////////
                    // MEMORY

                    if( parseInt( $('#'+did+'').find('select[name="purpose_id"]').val() ) != 3 )
                    {
                        dialog["buttons"][bi] = {};
                        dialog["buttons"][bi]["text"]  = " ";
                        dialog["buttons"][bi]["class"] = "type1";
                        dialog["buttons"][bi]["data-role"] = "to_mem";
                        dialog["buttons"][bi]["click"] = function()
                        {
                            var memory = {};

                            $('#'+did+'').find('[data-save="1"]').each(function()
                            {
                                var name = $(this).attr('name').toString();
                                var value = $(this).val().toString();
                                memory[name] = value;
                            });

                            memory["consume_list"] = {};
                            $('#'+did+'').find('#consume_list .consume[data-dispersion_id]').each(function()
                            {
                                var _item = $(this).attr('data-dispersion_id').toString();
                                var _count = $(this).find('input[name="consume_quantity"]').val();

                                memory["consume_list"][_item] = _count;
                            });

                            memory["reactiv_consume_list"] = {};
                            $('#'+did+'').find('#reactiv_consume_list  .consume[data-reactiv_hash]').each(function()
                            {
                                var _item = $(this).attr('data-reactiv_hash').toString();
                                var _count = $(this).find('input[name="consume_quantity"]').val();

                                memory["reactiv_consume_list"][_item] = _count;
                            });

                            var mem_post = {};
                                mem_post['ajax']        = 1;
                                mem_post['action']      = 1;
                                mem_post['subaction']   = 1;
                                mem_post['mod']         = 'memory';
                                mem_post['area']        = $('body').attr('data-mod');
                                mem_post['save']        = memory;

                            $.ajax({ data: mem_post }).done(function( _r )
                            {
                                _r = chem.txt2json( _r );
                            });
                        };
                        bi++;


                        dialog["buttons"][bi] = {};
                        dialog["buttons"][bi]["text"]  = " ";
                        dialog["buttons"][bi]["click"] = function()
                        {
                            var mem_post = {};
                                mem_post['ajax']        = 1;
                                mem_post['action']      = 2;
                                mem_post['subaction']   = 1;
                                mem_post['mod']         = 'memory';
                                mem_post['area']        = $('body').attr('data-mod');

                            $.ajax({ data: mem_post }).done(function( _r )
                            {
                                _r = chem.txt2json( _r );
                                if( _r['saved'] )
                                {
                                    $( '#'+did+'' ).find( '[data-save="1"][name="obj_count"]' ).val( _r['saved']['obj_count'] ).trigger( "change" );
                                    $( '#'+did+'' ).find( '[data-save="1"][name="purpose_id"]' ).val( _r['saved']['purpose_id'] ).trigger( "change" );

                                    for( k in _r['saved']['consume_list'] )
                                    {
                                        $( '#'+did+'' ).find( '#dispersion_list .line[data-id="'+k+'"]' ).trigger( "click" );

                                        while( chem.using._ADD_TRIGGER_ACTIVE )
                                        {
                                            setTimeout('', 10);
                                        }

                                        $( '#'+did+'' ).find( '#consume_list .consume[data-dispersion_id="'+k+'"]' ).find('input[name="consume_quantity"]').val( _r['saved']['consume_list'][k] ).trigger( "change" );
                                    }

                                    for( k in _r['saved']['reactiv_consume_list'] )
                                    {
                                        if( !$( '#'+did+'' ).find( '#cooked_list .line[data-hash="'+k+'"]' ).hasClass('dnone') )
                                        {
                                            $( '#'+did+'' ).find( '#cooked_list .line[data-hash="'+k+'"]' ).trigger( "click" );

                                            while( chem.using._ADD_TRIGGER_ACTIVE )
                                            {
                                                setTimeout('', 10);
                                            }

                                            $( '#'+did+'' ).find( '#reactiv_consume_list .consume[data-reactiv_hash="'+k+'"]' ).find('input[name="consume_quantity"]').val( _r['saved']['reactiv_consume_list'][k] ).trigger( "change" );
                                        }
                                    }

                                }
                            });
                        };
                        dialog["buttons"][bi]["class"] = "type1";
                        dialog["buttons"][bi]["data-role"] = "from_mem";
                        bi++;



                        dialog["buttons"][bi] = {};
                        dialog["buttons"][bi]["text"]  = " ";
                        dialog["buttons"][bi]["mouseenter"] = function()
                        {

                        }
                        dialog["buttons"][bi]["mouseleave"] = function()
                        {

                        }
                        dialog["buttons"][bi]["click"] = function()
                        {
                            if( $( '#templates_frame' ).attr('id') ){ return false; }

                            $(this).parent().append
                                    (
                                          '<div id="templates_frame" class="dnone">'
                                        + '<div class="create_new"><input type="text" name="template_name" class="input" value="" placeholder="������ ����� ��� ���������� ��������� ������"><button id="template_save" type="button">&nbsp;</button></div>'
                                        + '<div class="templates_list"></div>'
                                        + '</div>'
                                    );

                            $('#templates_frame').on('DOMNodeInserted', '.templates_list', function()
                            {
                                $( '#templates_frame .templates_list' ).find( '.template p' ).each( function()
                                {
                                    $(this).off().click( function()
                                    {
                                        var id = parseInt( $(this).parent().attr('data-id') );

                                        if( id == 0 )
                                        {
                                            $('#dispersion_list .line') .removeClass( 'dnone' );
                                            $('#cooked_list .line')     .removeClass( 'dnone' );
                                        }
                                        else
                                        {
                                            var ingridients = $(this).parent().attr('data-ingridients').split(';');

                                            $('#dispersion_list .line') .addClass( 'dnone' );
                                            $('#cooked_list .line')     .addClass( 'dnone' );

                                            ingridients.forEach(function(item, i, arr)
                                            {
                                                item = item.trim().toLowerCase();

                                                $('#dispersion_list .line').each( function()
                                                {
                                                    if( $(this).attr('data-name').toLowerCase() == item ){ $(this).removeClass( 'dnone' ) }
                                                } );

                                                $('#cooked_list .line').each( function()
                                                {
                                                    if( $(this).attr('data-name').toLowerCase() == item ){ $(this).removeClass( 'dnone' ) }
                                                } );
                                            });
                                        }

                                    });
                                } );
                                $('#templates_frame .templates_list').find('.template .remove').each(function()
                                {
                                    $(this).off().click( function()
                                    {
                                        var post = {};
                                            post['ajax'] = 1;
                                            post['action'] = 17;
                                            post['subaction'] = 1;
                                            post['mod'] = $('body').attr('data-mod');
                                            post['template_id'] = parseInt( $(this).attr('data-id') );

                                        $.ajax({ data: post }).done(function( _r )
                                        {
                                            _r = chem.txt2json( _r );
                                            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }
                                            $( '#templates_frame .templates_list' ).find('.template[data-id="'+post['template_id']+'"]').remove();
                                        });

                                    } );
                                });
                            });

                            var post = {};
                                post['ajax'] = 1;
                                post['action'] = 15;
                                post['subaction'] = 1;
                                post['mod'] = $('body').attr('data-mod');

                            $.ajax({ data: post }).done(function( _r )
                            {
                                _r = chem.txt2json( _r );
                                if( _r['error'] ){ console.log( _r['error_text'] ); return false; }
                                $( '#templates_frame .templates_list' ).html( _r['templates'] );
                            });

                            $( '#templates_frame' ).removeClass( 'dnone' );
                            $( '#templates_frame #template_save').click(function()
                            {
                                var inp = $(this).parent().find('[name="template_name"]');
                                var _list = [];

                                $( '#'+did + ' #consume_list .consume' ).each(function(){ _list.push( $(this).find('.reagent_name').text() ); });
                                $( '#'+did + ' #reactiv_consume_list .consume' ).each(function(){ _list.push( $(this).find('.reagent_name').text() ); });

                                if( inp.val().length < 5 ){ chem.BL_RED( inp ); return false; }
                                if( inp.val().length > 64 ){ chem.BL_RED( inp ); return false; }

                                var post = {};
                                    post['ajax'] = 1;
                                    post['action'] = 16;
                                    post['subaction'] = 1;
                                    post['mod'] = $('body').attr('data-mod');
                                    post['save'] = {};
                                    post['save']['name']        = inp.val();
                                    post['save']['ingridients'] = _list;

                                $.ajax({ data: post }).done(function( _r )
                                {
                                    inp.val( '' );
                                    _r = chem.txt2json( _r );
                                    if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

                                    $( '#templates_frame .templates_list' ).html( _r['templates'] );
                                });
                            });
                            $( '#templates_frame' ).mouseleave(function(){ $(this).remove(); });
                        };
                        dialog["buttons"][bi]["class"] = "type3";
                        dialog["buttons"][bi]["data-role"] = "show_templates";
                        bi++;
                    }
                    /////////////////////////////////////////////

                    if( line_hash != '' )
                    {
                        dialog["buttons"][bi] = {};
                        dialog["buttons"][bi]["text"]  = "��������";
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

        $('#content #list_frame #filters #print').on( "click", function()
        {
            var post = {};
                post['ajax']        = 1;
                post['action']      = 1000;
                post['mod']         = $('body').attr('data-mod');
                post['filters']     = {};

            $('#filters').find('[data-role="filter"]').each(function(){ post['filters'][$(this).attr('name')] = $(this).val(); });

            var url = window.location.origin + window.location.pathname + '?' + jQuery.param( post );

            window.location.replace( url );
        });
    }
}

$(document).ready( function()
{
    chem.using.init();
});