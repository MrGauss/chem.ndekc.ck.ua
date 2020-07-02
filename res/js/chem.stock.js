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

        $('#filters').find('select[data-role="filter"]').each(function(){ if( $(this).val() != '0' ){ post['filters'][$(this).attr('name')] = $(this).val(); }  });
        $('#filters').find('input[type="text"][data-role="filter"]').each(function(){ if( $(this).val() != '' ){ post['filters'][$(this).attr('name')] = $(this).val(); } });
        $('#filters').find('input[type="checkbox"][data-role="filter"]:checked').each(function(){ post['filters'][$(this).attr('name')] = $(this).val(); });

        if( line_id > 0 ){ post['filters']['id'] = line_id; }

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );

            if( _r['lines'] != undefined )
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
                        .off(  )
                        .on( "click", function(){ chem.stock.editor( $(this) ); } )
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
        chem.single_open( obj );

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

                autocomplete.init( $('#'+did+'') );

                $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ); });

                $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

                $('#'+did+' [name="reagent_id"]').each(function()
                {
                    $(this).on( 'change', function(){ $(this).parents('#'+did).find('input[name="units"]').val( $(this).find('option:selected').attr( 'data-units_name' ) ); } );
                });

                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]        = 2001;
                    dialog["modal"]         = true;
                    dialog["autoOpen"]      = true;
                    dialog["width"]         = '800';
                    dialog["resizable"]     = false;
                    dialog["buttons"]       = {};

                    dialog["buttons"][bi]               = {};
                    dialog["buttons"][bi]["text"]       = "Скасувати";
                    dialog["buttons"][bi]["click"]      = function(){ chem.close_it( $('#'+did) ); };
                    dialog["buttons"][bi]["class"]      = "type1";
                    dialog["buttons"][bi]["data-role"]  = "close_button";
                    bi++;

                    dialog["buttons"][bi]               = {};
                    dialog["buttons"][bi]["text"]       = "Зберегти";
                    dialog["buttons"][bi]["click"]      = function()
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

                    /////////////////////////////////////////////
                    // MEMORY
                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = " ";
                    dialog["buttons"][bi]["class"] = "type1";
                    dialog["buttons"][bi]["data-role"] = "to_mem";
                    dialog["buttons"][bi]["click"] = function()
                    {
                        var mem_post = {};
                            mem_post['ajax']        = 1;
                            mem_post['action']      = 1;
                            mem_post['subaction']   = 1;
                            mem_post['mod']         = 'memory';
                            mem_post['area']        = $('body').attr('data-mod');
                            mem_post['save']        = {};

                        $( '#'+did+'' ).find( '[data-save="1"]' ).not('[type="hidden"]').each(function()
                        {
                            mem_post['save'][$(this).attr('name')] = $(this).val();
                        });

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
                                for( k in _r['saved'] ){ $( '#'+did+'' ).find( '[data-save="1"][name="' + k + '"]' ).val( _r['saved'][k] ).trigger( "change" ); }
                            }
                        });
                    };
                    dialog["buttons"][bi]["class"] = "type1";
                    dialog["buttons"][bi]["data-role"] = "from_mem";
                    bi++;
                    /////////////////////////////////////////////

                    if( line_id )
                    {
                        dialog["buttons"][bi] = {};
                        dialog["buttons"][bi]["text"]  = "";
                        dialog["buttons"][bi]["click"] = function()
                        {
                            chem.stock.prolongation( $( '#'+did+'' ) );
                        };
                        dialog["buttons"][bi]["class"] = "type6";
                        dialog["buttons"][bi]["data-role"] = "terms";
                        bi++;
                    }

                    /////////////////////////////////////////////

                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = "Видалити";
                    dialog["buttons"][bi]["click"] = function()
                    {
                        if( confirm('Ви дійсно хочете видалити даний запис?') )
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
                        }

                    };
                    dialog["buttons"][bi]["class"] = "type5 right";
                    dialog["buttons"][bi]["data-role"] = "delete_button";
                    bi++;

                $('#'+did).dialog( dialog );
            }
        });
    }

    this.prolongation_remove = function( obj )
    {
        var hash        = obj.attr('data-hash');
        var stock_key   = obj.attr('data-key');
        var stock_id    = obj.attr('data-stock_id');

        var post = {};
            post['ajax'] = 1;
            post['action'] = 3;
            post['subaction'] = 1;
            post['mod']   = 'prolongation';
            post['hash']  = hash;
            post['key']   = stock_key;
            post['id']    = stock_id;



        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }
            obj.remove();
         });
    }

    this.prolongation = function( obj )
    {
        chem.single_open( obj );

        var stock_id  = obj.find('[name="id"]').val();
        var stock_key = obj.find('[name="key"]').val();

        var did_pref = 'stock-prolongation-form';
        var did = did_pref + '-' + stock_id + '-' + Math.floor((Math.random() * 1000000) + 1);

        var post = {};
            post['ajax'] = 1;
            post['action'] = 1;
            post['subaction'] = 1;
            post['mod'] = 'prolongation';
            post['id']  = stock_id;
            post['key'] = stock_key;

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            if( _r['form'] )
            {

                $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="Подовження термінів придатності">'+_r['form']+'</div>' );

                $('#'+did+'').find('[name="date_before_prolong"]').val( obj.find( '[name="dead_date"]' ).val() );

                autocomplete.init( $('#'+did+'') );

                $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ); });
                $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

                $('#'+did+'').find('#prolongation_history .list .line [data-role="remove"]')
                .off('click')
                .on('click', function()
                {
                    chem.stock.prolongation_remove( $(this).parents('.line') );
                });

                $('#'+did+' .show_add_panel').on( 'click', function()
                {
                    $(this).remove();
                    $('#'+did+'').find('.add_new').removeClass('dnone');
                    $('#'+did+'').dialog("widget").position({ "my": "top middle", "at": "top middle", "of": $(window) });
                });

                $('#'+did+' #add_prolong').on( 'click', function()
                {
                    var post = {};
                        post['ajax'] = 1;
                        post['action'] = 2;
                        post['subaction'] = 1;
                        post['mod']  = 'prolongation';
                        post['id']   = stock_id;
                        post['key']  = stock_key;
                        post['save'] = {};
                        post['save']['stock_id'] = stock_id;

                    if( chem.stock.check_before_save( $('#'+did) ) )
                    {
                        $('#'+did+'').find('[data-save="1"]').each(function()
                        {
                            post['save'][$(this).attr('name')] = $(this).val();
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
                                if( _r['lines'] )
                                {
                                    $('#'+did+'').find('[data-save="1"]').val( '' );

                                    obj.find( '[name="dead_date"]' ).val( _r['new_dead_date'] );

                                    chem.stock.reload( _r['id'] );

                                    $('#'+did+'').find('#prolongation_history .list').html( _r['lines'] );

                                    $('#'+did+'').find('#prolongation_history .list .line [data-role="remove"]')
                                    .off('click')
                                    .on('click', function()
                                    {
                                        chem.stock.prolongation_remove( $(this).parents('.line') );
                                    });
                                }
                            }




                        });
                    }
                });



                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]        = 2010;
                    dialog["modal"]         = true;
                    dialog["autoOpen"]      = true;
                    dialog["width"]         = '740';
                    dialog["resizable"]     = false;
                    dialog["buttons"]       = {};

                    dialog["buttons"][bi]               = {};
                    dialog["buttons"][bi]["text"]       = "Скасувати";
                    dialog["buttons"][bi]["click"]      = function(){ chem.close_it( $('#'+did) ); };
                    dialog["buttons"][bi]["class"]      = "type1";
                    dialog["buttons"][bi]["data-role"]  = "close_button";
                    bi++;

                $('#'+did).dialog( dialog );
            }
        });

        // dialog["zIndex"]        = 2001;


    }

    this.init = function()
    {
        $('#content .stock .line[data-id]') .off().on( "click", function(){ chem.stock.editor( $(this) ); });
        $('#content .stock #create')        .off().on( "click", function(){ chem.stock.editor( $(this) ); });

        $('#content .stock #filters #search').off().on( "click", function()
        {
            chem.stock.reload();
        });
    }
}

$(document).ready( function()
{
    chem.stock.init();
});