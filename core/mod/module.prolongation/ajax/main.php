<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !class_exists( 'prolongation' ) ) { require( CLASSES_DIR.DS.'class.prolongation.php' ); }

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
            ajax::set_data( 'form', (new prolongation)->editor( $_POST['id'] ) );
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
            if( (new prolongation)->save( $_POST['save'] ) )
            {
                ajax::set_data( 'lines', (new prolongation)->get_prolongation_list_html( $_POST['id'] ) );
            }

        }

    break;

    default:
        common::err( 'Дія невідома!' );
}

