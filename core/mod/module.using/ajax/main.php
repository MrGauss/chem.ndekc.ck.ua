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
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
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
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {
            ajax::set_data( 'hash', $using->remove( isset($_POST['hash'])?common::filter_hash($_POST['hash']):false ) );
        }
    break;

    case 4:
        $using = new using;

        $_POST['filters'] = ( isset($_POST['filters']) && is_array($_POST['filters']) )?$_POST['filters']:array();
        ajax::set_data( 'lines', $using->get_html( using::filters($_POST['filters']), 'using/line' ) );
    break;

    case 1000:
        $_REQUEST['filters'] = ( isset($_REQUEST['filters']) && is_array($_REQUEST['filters']) )?$_REQUEST['filters']:array();

        $tpl->load( 'using/print_main' );

        $_REQUEST['filters'] = using::filters( $_REQUEST['filters'] );

        foreach( $_REQUEST['filters'] as $filter_name => $filter_value )
        {
            if( is_array($filter_value) ){ continue; }
            $tpl->set( '{filter:'.$filter_name.'}', $filter_value );
        }
        $tpl->set( '{filter:using_date_from}',      $_REQUEST['filters']['using_date']['from'] );
        $tpl->set( '{filter:using_date_to}',        $_REQUEST['filters']['using_date']['to'] );

        $tpl->set( '{list}', (new using) -> get_html( $_REQUEST['filters'], 'using/print_line' ) );

        $caption = 'Використання';

        if( isset($_REQUEST['filters']['reagent_id']) && $_REQUEST['filters']['reagent_id'] )
        {
            $reagent = ( new spr_manager('reagent') )->get_raw( array( 'id'=>$_REQUEST['filters']['reagent_id'] ) )[$_REQUEST['filters']['reagent_id']];
            $caption = common::trim( $caption ) . ' реактиву (розхідного матеріалу) "'. common::db2html( $reagent['name'] ) .'"';
        }
        else
        {
            $caption = common::trim( $caption ) . ' реактивів та розхідних матеріалів';
        }

        $caption = common::trim( $caption ) . ' за період з '.$_REQUEST['filters']['using_date']['from'].' по '.$_REQUEST['filters']['using_date']['to'].'';

        if( isset($_REQUEST['filters']['expert_id']) && $_REQUEST['filters']['expert_id'] )
        {
            $expert = ( new user() )->get_raw( array( 'id'=>$_REQUEST['filters']['expert_id'] ) )[$_REQUEST['filters']['expert_id']];
            $caption = common::trim( $caption ) . ' експертом: '. common::db2html( $expert['surname'].' '.$expert['name'].' '.$expert['phname'] ) .'';
        }

        if( isset($_REQUEST['filters']['purpose_id']) && $_REQUEST['filters']['purpose_id'] )
        {
            $purpose = ( new spr_manager('purpose') )->get_raw( array( 'id'=>$_REQUEST['filters']['purpose_id'] ) )[$_REQUEST['filters']['purpose_id']];
            $caption = common::trim( $caption ) . ', з метою: '. common::db2html( $purpose['name'] ) .'';
        }

        $tpl->set( '{caption}', $caption );

        $tpl->compile( 'using/print_main' );

        $content =  strtr( $tpl->result( 'using/print_main' ), array
        (
            '{user_memory}' => round(memory_get_peak_usage()/1024,2).' kb',
            '{queries}' => isset($db->counters['queries'])?$db->counters['queries']:0,
            '{queries_cached}' => isset($db->counters['cached'])?$db->counters['cached']:0,
        ) );

        header( 'Content-Disposition: attachment; filename="'.common::win2utf( 'Використання реактивів та розхідних матеріалів '.date( 'Y.m.d H-i-s' ) ).'.html"' );
        header( 'Content-Type: text/html' );
        header( 'Content-Length: ' . strlen( $content ) );
        header( 'Connection: close' );

        echo $content;

        exit;

    break;

    default:
        common::err( 'Дія невідома!' );
}


