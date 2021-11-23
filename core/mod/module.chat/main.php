<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', '×àò' ); }

// access::check( 'admin', 'access' );

$tpl->load( _MOD_.'/main' );

$tpl->set( '{messages}', (new chat) -> get_html() );

$tpl->compile( _MOD_.'/main' );
$tpl->ins( 'main', $tpl->result( _MOD_.'/main' ) );
$tpl->clean( _MOD_.'/main' );