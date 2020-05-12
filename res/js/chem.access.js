$(document).ready( function()
{
    $('input[type="checkbox"][data-group_id][data-action_id]').on( 'change', function()
    {
        var act     = $(this).is(":checked") ? 'add' : 'del';
        var act_id  = $(this).attr( 'data-action_id' );
        var grp_id  = $(this).attr( 'data-group_id' );

        var post = {};
            post['ajax'] = 1;
            post['action'] = 1;
            post['subaction'] = 1;
            post['mod']      = 'access';
            post['act_id']   = act_id;
            post['grp_id']   = grp_id;
            post['act']      = act;

        $.ajax({ data: post }).done(function( _r )
        {
            _r = chem.txt2json( _r );
            if( _r['error'] ){ console.log( _r['error_text'] ); return false; }
        });

    } );
});