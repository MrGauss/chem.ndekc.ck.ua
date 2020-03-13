chem['stock'] = new function()
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

    this.reload = function( line_id )
    {
        line_id = parseInt( line_id );
        line_id = line_id ? line_id : 0;

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

        if( line_id > 0 ){ post['filters']['id'] = line_id; }

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );

            if( _r['lines'] )
            {
                if( line_id > 0 )
                {
                    $('#content .stock .list [data-id="'+line_id+'"]')
                        .off()
                        .replaceWith( _r['lines'] );

                    $('#content .stock .list [data-id="'+line_id+'"]')
                        .on( "click", function(){ chem.stock.editor( $(this) ); })
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
                    $('#content .stock .list [data-id]').off().remove();
                    $('#content .stock .list').append( _r['lines'] );
                    $('#content .stock [data-id]')
                        .on( "click", function(){ chem.stock.editor( $(this) ); })
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

    this.editor = function( obj )
    {
        var line_id = parseInt( obj.attr('data-id') );
        var did_pref = 'stock-edit-form';
        var did = did_pref + '-' + line_id + '-' + Math.floor((Math.random() * 1000000) + 1);

        chem.close_it( $('[id*="'+did_pref+'"]') );

        var post = {};
            post['ajax'] = 1;
            post['action'] = 1;
            post['subaction'] = 1;
            post['mod'] = $('body').attr('data-mod');
            post['id'] = line_id;

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            if( _r['form'] )
            {
                $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="Облік надходжень реактивів і витратних матеріалів: '+(line_id?'редагування запису':'створення запису')+'">'+_r['form']+'</div>' );

                $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ); });

                $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]  = 2001;
                    dialog["modal"]   = true;
                    dialog["autoOpen"]   = true;
                    dialog["width"]   = '700';
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

                        if( chem.stock.check_before_save( $('#'+did) ) )
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
                                        chem.stock.reload();
                                    }
                                    else
                                    {
                                        if( _r['id'] > 0 )
                                        {
                                            chem.animate_opacity( $('#'+did+' .good_area'), 'Дані успішно збережено!' );
                                            chem.stock.reload( _r['id'] );
                                        }
                                    }
                                }
                            });
                        }

                    };

                    dialog["buttons"][bi]["class"] = "type2";
                    dialog["buttons"][bi]["data-role"] = "close_button";
                    bi++;

                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = "Видалити";
                    dialog["buttons"][bi]["click"] = function()
                    {
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
                                chem.stock.reload();
                            }
                        });
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
        $('#content .stock [data-id]').on( "click", function()
        {
            chem.stock.editor( $(this) );
        });

        $('#content .stock #filters #search').on( "click", function()
        {
            chem.stock.reload();
        });
    }
}

$(document).ready( function()
{
    chem.stock.init();
});