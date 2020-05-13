<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'users', 'edit' );

$_POST['line_id']    = isset($_POST['line_id'])  ? common::integer( $_POST['line_id'] )  : false;
$_POST['line_key']   = isset($_POST['line_key']) ? common::filter( $_POST['line_key'] ) : false;

if( !common::key_check( 'user-'.$_POST['line_id'], $_POST['line_key'] ) )
{
    ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
}
else
{
    switch ( _ACTION_ )
    {
        case 1:
            ajax::set_data( 'form', ( new user )->editor( common::integer( isset($_REQUEST['line_id'])?$_REQUEST['line_id']:0 ) ) );
        break;

        case 2:

            if( ( $ID = ( new user )->save( isset($_POST['save'])?$_POST['save']:array() ) ) )
            {
                ajax::set_data( 'user_id', $ID );
                ajax::set_data( 'list', ( new user )->get_html( $_POST['line_id']?array('id'=>$_POST['line_id']):array() ) );
            }

        break;

        default: common::err( 'Дія невідома!' );
    }
}




