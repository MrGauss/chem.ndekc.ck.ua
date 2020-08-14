<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Експерти' ); }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'users', 'edit' );

$tpl->load( 'users/main' );

$tpl->set( '{null_user:key}', common::key_gen( 'user-0' ) );
$tpl->set( '{list}', ( new user )->get_html( array( 'visible' => 1, 'group_id' => CURRENT_GROUP_ID ) ) );

$tpl->compile( 'users/main' );
$tpl->ins( 'main', $tpl->result( 'users/main' ) );
$tpl->clean( 'users/main' );