<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !class_exists( 'transfer' ) ) { require( CLASSES_DIR.DS.'class.transfer.php' ); }
if( !access::check( 'stock', 'edit' ) ) { return false; }

switch ( _ACTION_ )
{

    case 100:

        $_POST['id']    = common::integer( isset($_POST['id'])?$_POST['id']:false );
        $_POST['to_group_id']    = common::integer( isset($_POST['to_group_id'])?$_POST['to_group_id']:false );
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'list', ( new transfer )->get_user_select( $_POST['to_group_id'] ) );
            ajax::set_data( 'reagents', ( new transfer )->get_reagent_select( $_POST['to_group_id'] ) );
        }
    break;

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
            if( ( $save = (new transfer)->save( $_POST['save'] ) ) > 0 )
            {
                ajax::set_data( 'transfer_id', $save );
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

