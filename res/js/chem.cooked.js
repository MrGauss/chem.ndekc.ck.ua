chem['cooked'] = new function()
{
    this.check_before_save = function( obj )
    {
        var did = obj.attr('hash');
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
        line_hash = line_hash ? line_hash : false;

        var post = {};
            post['ajax'] = 1;
            post['action'] = 4;
            post['subaction'] = 1;
            post['mod'] = $('body').attr('data-mod');
            post['filters'] = {};

        $('#filters').find('[data-role="filter"]').each(function()
        {
            post['filters'][$(this).attr('name')] = $(this).val();
        });

        if( line_hash != '' ){ post['filters']['hash'] = line_hash; }

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );

            if( _r['lines'] )
            {
                if( line_hash.length == 32 )
                {
                    $('#content #list_frame .list .line[data-hash="'+line_hash+'"]')
                        .off()
                        .replaceWith( _r['lines'] );

                    $('#content #list_frame .list .line[data-hash="'+line_hash+'"]')
                        .off()
                        .on( "click", function(){ chem.cooked.editor( $(this) ); })
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
                        .on( "click", function(){ chem.cooked.editor( $(this) ); })
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


    this.sort_ingridients = function( obj )
    {
        if( chem.cooked._STILL_SORT ){ return false; }

        chem.cooked._STILL_SORT = false;

        var direction = 'ASC';

        obj.find('.reagent')
        .sort(function(a,b)
        {
            var a_pos = parseInt( $(a).prop('data-position') );
            var b_pos = parseInt( $(b).prop('data-position') );

            console.log( 'SORTING - A: '+a_pos+' B:'+b_pos );

            if( a_pos > b_pos ){ return -1; }
            if( b_pos > a_pos ){ return  1; }
            return 0;
        })
        .detach().appendTo( obj );
    }

    this.recipe_selceted = function( recipe_id, selected_opt, dialog_window )
    {
        recipe_id = parseInt( recipe_id );

        var ingredients_reagent = recipe_id
                                ? selected_opt.attr('data-ingredients_reagent').toString().split( ','.toString() )
                                : 0;

        var ingredients_reactiv = recipe_id
                                ? selected_opt.attr('data-ingredients_reactiv').toString().split( ','.toString() )
                                : 0;

        ///
        dialog_window
            .find('#ingridients .reagent[data-reagent_id]')
                .removeClass( 'needed' )
                .addClass( 'not_needed' )
                .attr('data-position', 0 )
                .prop('data-position', 0 );

        for (var k in ingredients_reagent )
        {
            dialog_window.find('#ingridients')
                .find('.reagent[data-role="reagent"][data-reagent_id="'+ingredients_reagent[k]+'"]')
                    .addClass( 'needed' )
                    .removeClass( 'not_needed' )
                    .attr('data-position', 1 )
                    .prop('data-position', 1 );
        };

        /*for (var k in ingredients_reactiv )
        {
            dialog_window.find('#ingridients')
                .find('.reagent[data-reagent_id="'+ingredients_reactiv[k]+'"]')
                    .addClass( 'needed' )
                    .removeClass( 'not_needed' )
                    .attr('data-position', 1 )
                    .prop('data-position', 1 );
        };*/
        ///

        chem.cooked.sort_ingridients( dialog_window.find('#ingridients') );
        chem.cooked.resize_dialog( dialog_window, recipe_id );

        //

        dialog_window.find('select[name="units_id"]')
            .val( parseInt( selected_opt.attr('data-units_id') ) )
            .attr( 'disabled', 'disabled' )
            .prop( 'disabled', true );
    }

    this.resize_dialog = function( dialog_window, recipe_id )
    {
        var width           = dialog_window.dialog( 'option', 'width' );
        var normal_width    = dialog_window.dialog( 'option', 'normal_width' );

        var param_panel_height  = 0;
        var label_height        = 0;

        if( recipe_id > 0 )
        {
            dialog_window.find('.recipe_needed').removeClass('dnone');
            dialog_window.dialog( 'option', 'width', normal_width );

            dialog_window
                .find( '.recipe_needed .input' )
                    .attr( 'disabled', false)
                    .prop( 'disabled', false );

            //

            param_panel_height = 0;
            dialog_window.find('#param_panel .elems_line').each(function()
            {
                param_panel_height = param_panel_height + parseInt( $(this).height() );
            });

            label_height        = dialog_window.find('#param_panel .label:first').height();

            //dialog_window.find('.ingridients_panel').height( param_panel_height );
            //dialog_window.find('.ingridients_panel .list').height( ( ( param_panel_height - label_height ) / 2 ) - 27 );
        }
        else
        {
            dialog_window.find('.recipe_needed').removeClass('dnone').addClass('dnone');

            dialog_window
                .find( '.recipe_needed .input' )
                .attr( 'disabled', 'disabled' )
                .prop( 'disabled', true );

            dialog_window.dialog( 'option', 'width', 415 );

            dialog_window
                .find('table.panel .panel .list')
                    .height( 100 );
        }

        dialog_window.dialog("widget").position({ my: "center", at: "center", of: window });
    }

    this.add_to_composition = function( obj )
    {
        if( !obj.hasClass('needed') ){ return false; }
        if(  obj.hasClass('dnone') ) { return false; }

        obj.addClass( 'dnone' );

        var dialog_obj = obj.parents( '.default_editor' );
        var empty_obj  = dialog_obj.find( '#empty_composition .reagent' );

        empty_obj.attr( 'data-consume_hash', '' );
        empty_obj.attr( 'data-reagent_name',        obj.attr( 'data-reagent_name' ) );
        empty_obj.attr( 'data-reagent_id',          obj.attr( 'data-reagent_id' ));
        empty_obj.attr( 'data-dispersion_id',       obj.attr( 'data-dispersion_id' ));
        empty_obj.attr( 'data-reactiv_hash', '' );
        empty_obj.attr( 'data-quantity',     '' );
        empty_obj.attr( 'data-quantity_left',       obj.attr( 'data-quantity_left' ) );
        empty_obj.attr( 'data-reagent_units_short', obj.attr( 'data-reagent_units_short' ) );
        empty_obj.attr( 'data-inc_date',            obj.attr( 'data-inc_date' ) );

        empty_obj.find( '.reagent_name' ).html(         empty_obj.attr( 'data-reagent_name' ) );
        empty_obj.find( '.quantity_left' ).html(        empty_obj.attr( 'data-quantity_left' ) );
        empty_obj.find( 'input[max]' ).attr( 'max',     empty_obj.attr( 'data-quantity_left' ) );
        empty_obj.find( '.reagent_units_short' ).html(  empty_obj.attr( 'data-reagent_units_short' ) );
        empty_obj.find( '.inc_date span' ).html(        empty_obj.attr( 'data-inc_date' ) );
        empty_obj.find( '[name="quantity"]' ).val( '' );

        empty_obj
            .clone()
            .appendTo( dialog_obj.find( '#composition' ) )
            .find('[data-role="button"]')
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
            });
    }

    this.editor = function( obj )
    {
        chem.single_open( obj );

        var line_hash = obj.attr('data-hash');
        var did_pref = 'cooked-edit-form';
        var did = did_pref + '-' + line_hash + '-' + Math.floor((Math.random() * 1000000) + 1);
        var dialog_width = 920;

        chem.close_it( $('[id*="'+did_pref+'"]') );

        var post = {};
            post['ajax'] = 1;
            post['action'] = 1;
            post['subaction'] = 1;
            post['mod'] = $('body').attr('data-mod');
            post['hash'] = line_hash;

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );

            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            if( _r['form'] )
            {
                $('#ajax').append( '<div id="'+did+'" data-needed_width="'+dialog_width+'" data-role="dialog:window" title="Приготування робочих реактивів: '+( line_hash ? 'редагування запису':'створення запису')+'">'+_r['form']+'</div>' );

                autocomplete.init( $('#'+did+'') );

                $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ).trigger( "change" ); });
                $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

                if( line_hash )
                {
                    $('#'+did+' select[name="reactiv_menu_id"]')
                        .attr( 'disabled', 'disabled' )
                        .prop( 'disabled', true );
                }

                $('#'+did+' #composition .reagent').each( function()
                {
                    $('#'+did ).find( '#ingridients [data-dispersion_id="' + $(this).attr( 'data-dispersion_id' ) + '"]' ).addClass( 'dnone' );
                });

                $('#'+did+'').on( "dialogopen", function( event, ui )
                {
                    $('#'+did+' select[name="reactiv_menu_id"]').on( 'change', function()
                    {
                        chem.cooked.recipe_selceted( $(this).val(), $(this).find('option:selected'), $('#'+did+'') );
                    } ).trigger( "change" );

                    $('#'+did+' #ingridients .reagent [data-role="button"]').on( "click", function( event, ui )
                    {
                        chem.cooked.add_to_composition( $(this).parents('.reagent') );
                    });
                } );

                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]  = 2001;
                    dialog["modal"]   = true;
                    dialog["autoOpen"]   = true;
                    dialog["width"]          = dialog_width;
                    dialog["normal_width"]   = dialog["width"];
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

                        if( chem.cooked.check_before_save( $('#'+did) ) )
                        {
                            var post = {};
                                post['ajax'] = 1;
                                post['action'] = 2;
                                post['subaction'] = 1;

                                post['mod']    = $('body').attr('data-mod');
                                post['hash']   = $('#'+did).find('input[name="hash"]').val();
                                post['key']    = $('#'+did).find('input[name="key"]').val();
                                post['save']   = {};

                            $('#'+did).find('[data-save="1"]').each( function()
                            {
                                post['save'][$(this).attr('name').toString()] = $(this).val().toString();
                            } );

                            post['save']['composition'] = new Array;

                            $('#'+did + ' #composition .reagent[data-role="reagent"]' ).each(function()
                            {
                                post['save']['composition'].push
                                (
                                    {
                                        'dispersion_id':    $(this).attr( 'data-dispersion_id' ),
                                        'consume_hash':     $(this).attr( 'data-consume_hash' ),
                                        'reagent_id':       $(this).attr( 'data-reagent_id' ),
                                        'reactiv_hash':     $(this).attr( 'data-reactiv_hash' ),
                                        'quantity':         $(this).find('[name="quantity"]').val(),
                                        'role':             $(this).attr( 'data-role' )
                                    }
                                );
                            });

                            $.ajax({ data: post }).done(function( _r )
                            {
                               try{ _r = jQuery.parseJSON( _r ); }catch(err){ chem.err( 'ERROR: '+err+"\n\n"+_r ); return false; }

                                _r['error'] = parseInt(_r['error']);
                                _r['id'] = parseInt(_r['id']);

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
                                    // alert( line_hash+':'+_r['hash'] );
                                    if( !line_hash || line_hash != _r['hash'] )
                                    {
                                        chem.close_it( $('#'+did) );
                                        chem.cooked.reload();
                                    }
                                    else
                                    {
                                        if( _r['hash'] != '' )
                                        {
                                            chem.cooked.reload( _r['hash'] );
                                            chem.close_it( $('#'+did) );
                                            //$('#content #list_frame [data-hash="'+_r['hash']+'"]').trigger( "click" );
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
                                post['mod'] = $('body').attr('data-mod');
                                post['hash']   = $('#'+did).find('input[name="hash"]').val();
                                post['key']    = $('#'+did).find('input[name="key"]').val();

                            $.ajax({ data: post }).done(function( _r )
                            {
                                _r = chem.txt2json( _r );

                                if( _r['hash'] != '' )
                                {
                                    $('#list .line[data-hash="'+_r['hash']+'"]').remove();
                                    chem.close_it( $('#'+did) );
                                    chem.cooked.reload();
                                }
                            });
                        };
                        dialog["buttons"][bi]["class"] = "type5 right";
                        dialog["buttons"][bi]["data-role"] = "delete_button";
                        bi++;
                    }

                $('#'+did).dialog( dialog );
            }
        });
    }

    this.init = function()
    {
        $('#list_frame [data-hash]').on( "click", function()
        {
            chem.cooked.editor( $(this) );
        });

        $('#list_frame #filters #search').on( "click", function()
        {
            chem.cooked.reload();
        });
    }
}

$(document).ready( function()
{
    chem.cooked.init();
});