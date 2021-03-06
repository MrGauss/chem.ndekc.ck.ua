chem['dispersion'] = new function()
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
                    $('#content #list_frame .list .line[data-id="'+line_id+'"]')
                        .off()
                        .replaceWith( _r['lines'] );

                    $('#content #list_frame .list .line[data-id="'+line_id+'"]')
                        .off()
                        .on( "click", function(){ chem.dispersion.editor( $(this) ); })
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
                        .off()
                        .on( "click", function(){ chem.dispersion.editor( $(this) ); })
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
        var did_pref = 'dispersion-edit-form';
        var did = did_pref + '-' + line_id + '-' + Math.floor((Math.random() * 1000000) + 1);

        chem.close_it( $('[id*="'+did_pref+'"]') );

        var post = {};
            post['ajax'] = 1;
            post['action'] = 1;
            post['subaction'] = 1;
            post['mod']     = $('body').attr('data-mod');
            post['id']      = line_id;
            post['rand']    = Math.floor((Math.random() * 1000000) + 1);

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            if( _r['form'] )
            {
                $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="���� ������ �������� � ��������� ��������: '+(line_id?'����������� ������':'��������� ������')+'">'+_r['form']+'</div>' );

                autocomplete.init( $('#'+did+'') );    

                if( line_id > 0 )
                {
                    $('#'+did+' select[name="stock_id"]').prop( 'readonly', true );
                }

                $('#'+did+' select[name="stock_id"]').on( "change", function()
                {
                    var opt = $(this).find('option:selected');
                    $('#'+did+'  [name="reagent_quantity_left"]').val( opt.attr('data-quantity_left') );
                });


                $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ).trigger( "change" ); });

                $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
                $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

                var bi = 0;
                var dialog = {};
                    dialog["zIndex"]  = 2001;
                    dialog["modal"]   = true;
                    dialog["autoOpen"]   = true;
                    dialog["width"]   = '553';
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

                        if( chem.dispersion.check_before_save( $('#'+did) ) )
                        {
                            var save_post = {};
                                save_post['ajax'] = 1;
                                save_post['action'] = 2;
                                save_post['subaction'] = 1;
                                save_post['mod'] = $('body').attr('data-mod');
                                save_post['rand'] = Math.floor((Math.random() * 1000000) + 1);
                                save_post['id']  = $('#'+did).find('input[name="id"]').val();
                                save_post['key'] = $('#'+did).find('input[name="key"]').val();
                                save_post['save'] = {};

                            $('#'+did).find('[data-save="1"]').each( function()
                            {
                                // alert( $(this).attr('name') + ' : ' + $(this).val().toString() );
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
                                        setTimeout( function(){ chem.close_it( $('#'+did) ); } , 1 );
                                        setTimeout( function(){ chem.dispersion.reload(); } , 2 );
                                    }
                                    else
                                    {
                                        if( _r['id'] > 0 )
                                        {
                                            // chem.animate_opacity( $('#'+did+' .good_area'), '���� ������ ���������!' );

                                            setTimeout( function(){ chem.dispersion.reload( _r['id'] ); } , 1 );
                                            setTimeout( function(){ chem.close_it( $('#'+did) ); } , 2 );
                                            setTimeout( function(){ $('#content #list_frame [data-id="'+_r['id']+'"]').trigger( "click" ); } , 3 );

                                            //
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
                    dialog["buttons"][bi]["text"]  = "��������";
                    dialog["buttons"][bi]["click"] = function()
                    {
                        if( confirm('�� ����� ������ �������� ����� �����?') )
                        {
                            var save_post = {};
                                save_post['ajax'] = 1;
                                save_post['action'] = 3;
                                save_post['subaction'] = 1;
                                save_post['mod'] = $('body').attr('data-mod');
                                save_post['id']  = $('#'+did).find('input[name="id"]').val();
                                save_post['key'] = $('#'+did).find('input[name="key"]').val();
                                save_post['rand'] = Math.floor((Math.random() * 1000000) + 1);

                            $.ajax({ data: save_post }).done(function( _r )
                            {
                                _r = chem.txt2json( _r );
                                _r['id'] = parseInt(_r['id']);

                                if( _r['id'] > 0 )
                                {
                                    $('#list .line[data-id="'+_r['id']+'"]').remove();
                                    chem.close_it( $('#'+did) );

                                    chem.dispersion.reload();
                                }
                            });
                        }

                    };
                    dialog["buttons"][bi]["class"] = "type5 right";
                    dialog["buttons"][bi]["data-role"] = "delete_button";
                    bi++;

                    /////////////////////////////////////////////
                    // MEMORY
                    dialog["buttons"][bi] = {};
                    dialog["buttons"][bi]["text"]  = " ";
                    dialog["buttons"][bi]["class"] = "type1 dispersion";
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
                    dialog["buttons"][bi]["class"] = "type1 dispersion";
                    dialog["buttons"][bi]["data-role"] = "from_mem";
                    bi++;
                    /////////////////////////////////////////////

                $('#'+did).dialog( dialog );
            }
        });
    }

    this.init = function()
    {
        $('#content #list_frame [data-id]').on( "click", function()
        {
            chem.dispersion.editor( $(this) );
        });

        $('#content #list_frame #filters #search').on( "click", function()
        {
            chem.dispersion.reload();
        });
    }
}

$(document).ready( function()
{
    chem.dispersion.init();
});