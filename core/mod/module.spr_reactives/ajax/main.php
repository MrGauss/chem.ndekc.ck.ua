<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

switch ( _ACTION_ )
{
    case 1:
        $spr = new spr_manager('reagent');
        ajax::set_data( 'form', $spr->editor( common::integer( isset($_POST['id'])?$_POST['id']:0 ),  _MOD_.'/editor' ) );
    break;

    case 2:
        $spr = new spr_manager('reagent');

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $spr->save( isset($_POST['id'])?common::integer($_POST['id']):false, isset($_POST['save'])?$_POST['save']:false ) );
        }

    break;

    case 3:
        $spr = new spr_manager('reagent');

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $spr->remove( isset($_POST['id'])?common::integer($_POST['id']):false ) );
        }
    break;

    case 4:

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        $spr = new spr_manager('reagent');

        ajax::set_data( 'lines', $spr->get_html( $_POST['filters'],  _MOD_.'/line' ) );
    break;

    default:
        common::err( 'Дія невідома!' );
}


