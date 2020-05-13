chem['users'] = new function()
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

    this.edit = function( obj )
    {
        var line_id  = parseInt( obj.attr( 'data-id' ) );
        var line_key = obj.attr( 'data-key' );

        chem.single_open( obj );

        var did_pref = 'stock-edit-form';
        var did = did_pref + '-' + line_id + '-' + Math.floor((Math.random() * 1000000) + 1);

        chem.close_it( $('[id*="'+did_pref+'"]') );

        var post = {};
            post['ajax']        = 1;
            post['action']      = 1;
            post['subaction']   = 1;
            post['mod']         = $('body').attr('data-mod');
            post['line_id']     = line_id;
            post['line_key']    = line_key;

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );

            if( !_r['form'] ){ return false; }

            $('#ajax').append( '<div id="'+did+'" data-role="dialog:window" title="Користувачі: '+(line_id? 'редагування запису' : 'створення запису' )+'">'+_r['form']+'</div>' );

            $('#'+did+'').find('select[data-value]').each(function(){ $(this).val( $(this).attr('data-value') ).trigger( "change" ); });
            $('#'+did+'').find('input[name*="date"]').each(function(){ chem.init_datepicker( $(this) ); });
            $('#'+did+' [data-mask]').each(function(){ chem.init_mask( $(this) ); });

            if( !line_id )
            {
                $('#'+did+'').find('input[name="login"]').removeAttr('readonly').removeAttr('disabled').prop('data-important', '1' ).attr('data-important', '1').prop('data-save', '1' ).attr('data-save', '1');
                $('#'+did+'').find('input[name="password"]').removeAttr('readonly').removeAttr('disabled').prop('data-important', '1' ).attr('data-important', '1').prop('data-save', '1' ).attr('data-save', '1');
            }
            else
            {
                $('#'+did+'').find('input[name="password"]').dblclick( function()
                {
                    $(this).removeAttr('disabled').removeAttr('readonly').prop('data-important', '1' ).attr('data-important', '1').prop('data-save', '1' ).attr('data-save', '1').attr('placeholder', '');
                } );
            }

            var bi = 0;
            var dialog = {};
                dialog["zIndex"]        = 2001;
                dialog["modal"]         = true;
                dialog["autoOpen"]      = true;
                dialog["width"]         = '400';
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
                    if( chem.users.check_before_save( $('#'+did) ) )
                    {
                        var post = {};
                            post['ajax']        = 1;
                            post['action']      = 2;
                            post['subaction']   = 1;
                            post['mod']         = $('body').attr('data-mod');
                            post['line_id']     = line_id;
                            post['line_key']    = line_key;
                            post['save']        = {};

                        $('#'+did).find('[data-save="1"]').each(function()
                        {
                            post['save'][$(this).attr('name')] = $(this).val();
                        });

                        $.ajax({ data: post }).done(function( _r )
                        {
                            _r = chem.txt2json( _r );

                            if( parseInt( _r['user_id'] ) > 0 )
                            {
                                if( line_id > 0 )
                                {
                                    $('#users_editor .line_user[data-id="'+line_id+'"]').replaceWith( _r['list'] );

                                    var cls = $('#users_editor .line_user[data-id="'+line_id+'"]').attr('data-label');

                                        $('#users_editor .line_user[data-id="'+line_id+'"]')
                                        .addClass('blink').removeClass( cls )
                                        .switchClass( 'blink', cls, 1000, 'swing', function()
                                        {
                                            $(this).removeClass('blink');
                                            $(this).removeClass(cls);
                                            $(this).addClass(cls);
                                        } );

                                }
                                else
                                {
                                    $('#users_editor .line_user[data-id]').not('.line_user[data-id="0"]').off().remove();
                                    $('#users_editor').append( _r['list'] );

                                        $('#users_editor .line_user[data-id]')
                                        .addClass('blink')
                                        .switchClass( 'blink', 'normal', 1000, 'swing', function()
                                        {
                                            $(this).removeClass('blink').removeClass('normal');
                                        } );
                                }

                                $('#users_editor .line_user').off().on( 'click', function(){ chem.users.edit( $(this) ); } );
                                chem.close_it( $('#'+did) );
                            }
                        });

                    }

                };
                dialog["buttons"][bi]["class"]      = "type2";
                dialog["buttons"][bi]["data-role"]  = "іфму_button";

            $('#'+did).dialog( dialog );


        });

    }
}



$(document).ready( function()
{
    $('#users_editor .line_user').on( 'click', function(){ chem.users.edit( $(this) ); } );
});