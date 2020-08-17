<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'stock', 'view' );

if( !class_exists( 'transfer' ) ) { require( CLASSES_DIR.DS.'class.transfer.php' ); }

switch ( _ACTION_ )
{
    case 1:

        $_POST['id']    = common::integer( isset($_POST['id'])?$_POST['id']:false );
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'form', (new transfer)->editor( $_POST['id'] ) );
        }

    break;

    case 2:

        $_POST['id']    = common::integer( isset($_POST['id'])?$_POST['id']:false );
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            if( is_array( $save = (new transfer)->save( $_POST['save'] ) ) )
            {
                ajax::set_data( 'stock_id', $_POST['id'] );
            }

        }

    break;

    case 3:
        $_POST['id']    = common::integer( isset($_POST['id'])?$_POST['id']:false );
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            (new transfer)->remove( $_POST['id'], $_POST['hash'] );
        }

    break;

    default:
        common::err( 'Дія невідома!' );
}

