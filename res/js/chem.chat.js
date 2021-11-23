chem['chat'] = new function()
{
    this.reload = function()
    {
        console.log( 'interval processed...' );
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

    setInterval( function(){ chem.chat.reload() }, 15000);
});