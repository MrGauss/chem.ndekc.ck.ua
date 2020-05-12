<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !class_exists( 'prolongation' ) ) { require( CLASSES_DIR.DS.'class.prolongation.php' ); }

access::check( 'admin', 'access' );

switch ( _ACTION_ )
{
    case 1:

        (new access)->save( $_POST['act'], $_POST['act_id'], $_POST['grp_id'] );

    break;

    default:
        common::err( 'Дія невідома!' );
}

