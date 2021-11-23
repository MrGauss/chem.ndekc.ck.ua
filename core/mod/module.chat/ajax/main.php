<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

// access::check( 'admin', 'access' );

switch ( _ACTION_ )
{
    case 1:
        ( new chat ) -> save( $_REQUEST['message'] );
    break;

    case 2:
        ajax::set_data( 'reslt', (new chat) -> get_html() );
    break;

    default:
        common::err( 'Дія невідома!' );
}

