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

    case 3:
        ajax::set_data( 'unread', CURRENT_UNREAD_MESSAGES );
    break;

    default:
        common::err( 'Дія невідома!' );
}

