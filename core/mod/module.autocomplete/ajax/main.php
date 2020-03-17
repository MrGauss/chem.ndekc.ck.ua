<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

switch ( _ACTION_ )
{
    case 1:

        $_POST['term']      = common::filter( isset($_POST['term'])?$_POST['term']:false );
        $_POST['key']       = common::filter( isset($_POST['key'])?$_POST['key']:false );
        $_POST['table']     = common::filter( isset($_POST['table'])?$_POST['table']:false );
        $_POST['column']    = common::filter( isset($_POST['column'])?$_POST['column']:false );
        $_POST['top10']     = common::integer( isset($_POST['top10'])?$_POST['top10']:false ) ? true : false;

        if( !autocomplete::check_key( $_POST['key'], $_POST['table'], $_POST['column'] ) )
        {
            ajax::set_error( 1, 'Помилка даних! Оновіть сторінку!' );
        }
        else
        {     
            ajax::set_data( 'reslt', autocomplete::make( $_POST['table'], $_POST['column'], $_POST['term'], $_POST['top10'] ) );
        }

    break;


    default:
        common::err( 'Дія невідома!' );
}


