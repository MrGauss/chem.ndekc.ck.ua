<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'stock', 'view' ); 

switch ( _ACTION_ )
{
    case 1:
        $stock = new stock;
        ajax::set_data( 'form', $stock->editor( common::integer( isset($_REQUEST['id'])?$_REQUEST['id']:0 ), 'stock/editor' ) );
    break;

    case 2:
        $stock = new stock;

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
            // common::err( 'Дія невідома!' );
        }
        else
        {
            ajax::set_data( 'id', $stock->save( isset($_POST['id'])?common::integer($_POST['id']):false, isset($_POST['save'])?$_POST['save']:false ) );
        }

    break;

    case 3:
        $stock = new stock;

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $stock->remove( isset($_POST['id'])?common::integer($_POST['id']):false ) );
        }
    break;

    case 4:

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        $stock = new stock;
    
        ajax::set_data( 'lines', $stock->get_html( $_POST['filters'], 'stock/line' ) );
    break;

    default:
        common::err( 'Дія невідома!' );
}


