<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////


switch ( _ACTION_ )
{
    case 1:
        $recipes = new recipes;
        ajax::set_data( 'form', $recipes->editor( common::integer( isset($_POST['id'])?$_POST['id']:0 ),  _MOD_.'/editor' ) );
    break;

    case 2:
        $recipes = new recipes;

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $recipes->save( isset($_POST['id'])?common::integer($_POST['id']):false, isset($_POST['save'])?$_POST['save']:false ) );
        }

    break;

    case 3:
        $recipes = new recipes;

        $_POST['id']    = isset($_POST['id'])?$_POST['id']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['id'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'id', $recipes->remove( isset($_POST['id'])?common::integer($_POST['id']):false ) );
        }
    break;

    case 4:

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        $recipes = new recipes;

        ajax::set_data( 'lines', $recipes->get_html( $_POST['filters'],  _MOD_.'/line' ) );

    break;

    default:
        common::err( 'Дія невідома!' );
}


