chem['chat'] = new function()
{
    this.insertAtCursor = function( ins_filed, ins_text )
    {
        var cursorPos = ins_filed.prop('selectionStart');
        var v = ins_filed.val();
        var textBefore = v.substring(0,  cursorPos);
        var textAfter  = v.substring(cursorPos, v.length);

        ins_filed.val( textBefore + ins_text + textAfter );
    }


    this.ins_avtor_tag = function( obj )
    {
        var tag = '[@'+obj.attr('data-login')+']';
        chem.chat.insertAtCursor( $('#chat_textbox_textarea'), tag );
    }

    this.reload = function()
    {

        var post = {};
            post['ajax']        = 1;
            post['action']      = 2;
            post['mod']         = $('body').attr('data-mod');

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            if( _r['reslt'] )
            {
                $('#chat_messages').html( false );
                $('#chat_messages').html( _r['reslt'] );

                $('#chat_messages .message a[data-login]').off( "click" ).on( 'click', function(){ chem.chat.ins_avtor_tag( $(this) ); } );
            }
            return true;
        });
        return false;
    }

    this.save = function( obj )
    {
        if( obj.prop( 'disabled' ) ){ return false; }
        obj.attr( 'disabled', 'disabled' ).prop( 'disabled', 'disabled' );

        var msg_text = $('#chat_textbox_textarea').val();

        var post = {};
            post['ajax']        = 1;
            post['action']      = 1;
            post['subaction']   = 1;
            post['mod']         = $('body').attr('data-mod');
            post['message']     = msg_text;

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }

            $('#chat_textbox_textarea').val( '' );

            chem.chat.reload();
        });

        obj.attr( 'disabled', false ).prop( 'disabled', false );
    }

    this.get = function( obj )
    {

    }
}


$(document).ready( function()
{
    $('#chat_frame #chat_send_button').on( 'click', function(){ chem.chat.save( $(this) ); } );
    $('#chat_frame #chat_messages .message a[data-login]').off( "click" ).on( 'click', function(){ chem.chat.ins_avtor_tag( $(this) ); } );

    $('#chat_textbox_textarea').on('keydown', function( event )
    {
        if (!event.ctrlKey){ return true; }

        //console.log( 'KEY: '+event.which+'; CTRL: '+event.ctrlKey );
        if( event.which == 13 && event.ctrlKey ){ $('#chat_frame #chat_send_button').click(); }
    });

    chem.update_unread_messages();

    setInterval( function(){ chem.chat.reload() }, 5000);
});