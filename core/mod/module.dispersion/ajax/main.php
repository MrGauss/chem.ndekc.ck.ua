<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'dispersion', 'view' );

switch ( _ACTION_ )
{
    case 1:
        $dispersion = new dispersion;
        ajax::set_data( 'form', $dispersion->editor( common::integer( isset($_POST['id'])?$_POST['id']:0 ), 'dispersion/editor' ) );
    break;

    case 2:
        $dispersion = new dispersion;

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $dispersion->save( isset($_POST['id'])?common::integer($_POST['id']):false, isset($_POST['save'])?$_POST['save']:false ) );
        }

    break;

    case 3:
        $dispersion = new dispersion;

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $dispersion->remove( isset($_POST['id'])?common::integer($_POST['id']):false ) );
        }
    break;

    case 4:

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        $dispersion = new dispersion;

        ajax::set_data( 'lines', $dispersion->get_html( $_POST['filters'], 'dispersion/line' ) );
    break;

    default:
        common::err( 'Дія невідома!' );
}


