<?php
//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$_POST['area'] = isset($_POST['area']) ? $_POST['area'] : false;
if( !$_POST['area'] ){ common::err( 'AREA NOT SET!' );  }
$_POST['area'] = 'mem-'.md5( $_POST['area'] );

switch ( _ACTION_ )
{
    case 1:
        $_POST['save'] = isset($_POST['save']) ? $_POST['save'] : false;

        if( !$_POST['save'] ){ common::err( 'SAVE NOT SET!' );  }

        cache::set( $_POST['area'], $_POST['save'] );
        ajax::set_data( 'saved', $_POST['save'] );
    break;

    case 2:
        ajax::set_data( 'saved', cache::get( $_POST['area'] ) );
    break;

    default:
        common::err( 'Дія невідома!' );
}


