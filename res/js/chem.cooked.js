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

        if( line_hash > 0 ){ post['filters']['hash'] = line_hash; }

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

                    $('#content #list_frame .list .line[data-id="'+line_id+'"]')
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
                    $('#content #list_frame .list .line[data-id]').off().remove();
                    $('#content #list_frame .list').append( _r['lines'] );
                    $('#content #list_frame [data-id]')
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

    this.recipe_seleted = function( recipe_id, selected_opt, dialog_window )
    {
        recipe_id = parseInt( recipe_id );

        var opts = {};
            opts['duration'] = 300;
            opts['easing'] = 'easeInOutExpo';

        if( dialog_window.find('select[name="reactiv_menu_id"]').hasClass('fastchange') )
        {
            opts['duration'] = 10;
            dialog_window.find('select[name="reactiv_menu_id"]').removeClass('fastchange');
        }

        if( !dialog_window.parents('.ui-dialog').attr( 'data-width' ) )
        {
            dialog_window.parents('.ui-dialog').attr( 'data-width', dialog_window.parents('.ui-dialog').width() );
        }

        if( recipe_id > 0 )
        {
            opts['start'] = function()
            {
                dialog_window.parents('.ui-dialog').width( dialog_window.parents('.ui-dialog').attr( 'data-width' ) );
            };

            dialog_window.find('.recipe_needed').each(function()
            {
                if( $(this).hasClass('norecipe') ){ $(this).removeClass('norecipe'); }
                $(this).stop().show( opts );
            });
            dialog_window.find('.recipe_needed .input').attr('disabled', 'disabled').prop( 'disabled', false );
        }
        else
        {
            opts['start'] = function()
            {
                dialog_window.parents('.ui-dialog').attr( 'data-width', dialog_window.parents('.ui-dialog').width() );
            };

            opts['done'] = function()
            {
                dialog_window.parents('.ui-dialog').width( 400 );
            };

            dialog_window.find('.recipe_needed').each(function()
            {
                if( !$(this).hasClass('norecipe') ){ $(this).addClass('norecipe'); }
                $(this).stop().hide( opts );
            });
            dialog_window.find('.recipe_needed .input').attr('disabled', 'disabled').prop( 'disabled', true );
        }

        dialog_window.find('select[name="units_id"]').val( parseInt( selected_opt.attr('data-units_id') ) ).attr('disabled', 'disabled').prop('disabled', true );
    }

    this.editor = function( obj )
    {
        chem.single_open( obj );

        var line_hash = obj.attr('data-hash');
        var did_pref = 'cooked-edit-form';
        var did = did_pref + '-' + line_hash + '-' + Math.floor((Math.random() * 1000000) + 1);

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
                $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="������������ ������� ��������: '+( line_hash ? '����������� ������':'��������� ������')+'">'+_r['form']+'</div>' );

                autocomplete.init( $('#'+did+'') );

                $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ).trigger( "change" ); });

                $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

                $('#'+did+' select[name="reactiv_menu_id"]').on( 'change', function()
                {
                    chem.cooked.recipe_seleted( $(this).val(), $(this).find('option:selected'), $('#'+did+'') );
                } );

                $('#'+did+' select[name="reactiv_menu_id"]').addClass('fastchange').trigger( "change" );

                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]  = 2001;
                    dialog["modal"]   = true;
                    dialog["autoOpen"]   = true;
                    dialog["width"]   = '700';
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
                    { /*
                        if( !$('#'+did+' .error_area').hasClass('dnone') ){ $('#'+did+' .error_area').addClass('dnone'); }

                        if( chem.cooked.check_before_save( $('#'+did) ) )
                        {
                            var save_post = {};
                                save_post['ajax'] = 1;
                                save_post['action'] = 2;
                                save_post['subaction'] = 1;
                                save_post['mod'] = $('body').attr('data-mod');
                                save_post['id']  = $('#'+did).find('input[name="id"]').val();
                                save_post['key'] = $('#'+did).find('input[name="key"]').val();
                                save_post['save'] = {};

                            $('#'+did).find('[data-save="1"]').each( function()
                            {
                                save_post['save'][$(this).attr('name').toString()] = $(this).val().toString();
                            } );

                            $.ajax({ data: save_post }).done(function( _r )
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
                                    if( !line_id || line_id != _r['id'] )
                                    {
                                        chem.close_it( $('#'+did) );
                                        chem.cooked.reload();
                                    }
                                    else
                                    {
                                        if( _r['id'] > 0 )
                                        {
                                            // chem.animate_opacity( $('#'+did+' .good_area'), '���� ������ ���������!' );
                                            chem.cooked.reload( _r['id'] );
                                            chem.close_it( $('#'+did) );

                                            $('#content #list_frame [data-id="'+_r['id']+'"]').trigger( "click" );
                                        }
                                    }
                                }
                            });
                        }
                        */

                    };

                    dialog["buttons"][bi]["class"] = "type2";
                    dialog["buttons"][bi]["data-role"] = "close_button";
                    bi++;

                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = "��������";
                    dialog["buttons"][bi]["click"] = function()
                    { /*
                        var save_post = {};
                            save_post['ajax'] = 1;
                            save_post['action'] = 3;
                            save_post['subaction'] = 1;
                            save_post['mod'] = $('body').attr('data-mod');
                            save_post['id']  = $('#'+did).find('input[name="id"]').val();
                            save_post['key'] = $('#'+did).find('input[name="key"]').val();

                        $.ajax({ data: save_post }).done(function( _r )
                        {
                            _r = chem.txt2json( _r );
                            _r['id'] = parseInt(_r['id']);

                            if( _r['id'] > 0 )
                            {
                                $('#list .line[data-id="'+_r['id']+'"]').remove();
                                chem.close_it( $('#'+did) );

                                chem.cooked.reload();
                            }
                        });     */
                    };
                    dialog["buttons"][bi]["class"] = "type5 right";
                    dialog["buttons"][bi]["data-role"] = "delete_button";
                    bi++;

                $('#'+did).dialog( dialog );
            }
        });
    }

    this.init = function()
    {
        $('#content #list_frame [data-hash]').on( "click", function()
        {
            chem.cooked.editor( $(this) );
        });

        $('#content #list_frame #filters #search').on( "click", function()
        {
            chem.cooked.reload();
        });
    }
}

$(document).ready( function()
{
    chem.cooked.init();
});