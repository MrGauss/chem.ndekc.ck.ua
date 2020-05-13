<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'cooked', 'view' ); 

switch ( _ACTION_ )
{
    case 1:
        $cooked = new cooked;
        ajax::set_data( 'form', $cooked->editor( common::filter_hash( isset($_POST['hash'])?$_POST['hash']:false ), 'cooked/editor' ) );
    break;

    case 2:
        $cooked = new cooked;

        $_POST['hash']  = isset($_POST['hash']) ?   $_POST['hash']  :   false;
        $_POST['key']   = isset($_POST['key'])  ?   $_POST['key']   :   false;
        $_POST['save']  = isset($_POST['save']) ?   $_POST['save']  :   false;

        if( !common::key_check( $_POST['hash'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'hash', $cooked->save( isset($_POST['hash'])?common::filter_hash($_POST['hash']):false, isset($_POST['save'])?$_POST['save'] : array() ) );
        }

    break;

    case 3:
        $cooked = new cooked;

        $_POST['hash']    = isset($_POST['hash'])?$_POST['hash']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['hash'], $_POST['key'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'hash', $cooked->remove( isset($_POST['hash'])?common::filter_hash($_POST['hash']):false ) );
        }
    break;

    case 4:

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        $cooked = new cooked;

        ajax::set_data( 'lines', $cooked->get_html( $_POST['filters'], 'cooked/line' ) );
    break;

    default:
        common::err( 'Дія невідома!' );
}


