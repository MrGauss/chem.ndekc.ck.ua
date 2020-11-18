<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'using', 'view' );

switch ( _ACTION_ )
{
    case 1:
        $using = new using;
        ajax::set_data( 'form', $using->editor( common::filter_hash( isset($_POST['hash'])?$_POST['hash']:'' ), 'using/editor' ) );
    break;

    case 2:
        $using = new using;

        $_POST['hash']  = isset($_POST['hash'])?$_POST['hash']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;
        $_POST['save']  = isset($_POST['save'])?$_POST['save']:false;

        if( !common::key_check( $_POST['hash'], $_POST['key'] ) )
        {
            ajax::set_error( 1, '������� �����! ������ �������!' );
        }
        else
        {
            ajax::set_data( 'hash', $using->save( isset($_POST['hash'])?common::filter_hash($_POST['hash']):false, isset($_POST['save'])?$_POST['save']:false ) );
        }

    break;

    case 3:
        $using = new using;

        $_POST['hash']  = isset($_POST['hash'])?$_POST['hash']:false;
        $_POST['key']   = isset($_POST['key'])?$_POST['key']:false;

        if( !common::key_check( $_POST['hash'], $_POST['key'] ) )
        {
            ajax::set_error( 1, '������� �����! ������ �������!' );
        }
        else
        {
            ajax::set_data( 'hash', $using->remove( isset($_POST['hash'])?common::filter_hash($_POST['hash']):false ) );
        }
    break;

    case 4:

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        $using = new using;

        ajax::set_data( 'lines', $using->get_html( $_POST['filters'], 'using/line' ) );
    break;

    case 1000:

        //$dompdf = new dompdf;

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();

        $tpl->load( 'using/print_main' );
        $tpl->set( '{list}', (new using) -> get_html( $_POST['filters'], 'using/print_line' ) );
        $tpl->compile( 'using/print_main' );

        echo strtr( $tpl->result( 'using/print_main' ), array
        (
            '{user_memory}' => round(memory_get_peak_usage()/1024,2).' kb',
            '{queries}' => isset($db->counters['queries'])?$db->counters['queries']:0,
            '{queries_cached}' => isset($db->counters['cached'])?$db->counters['cached']:0,
        ) );

        exit;

    break;

    default:
        common::err( 'ĳ� �������!' );
}


