<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Рівні доступу' ); }

access::check( 'admin', 'access' );

$tpl->load( 'access/main' );

$tpl->set( '{editor}', ( new access )->editor() );

$tpl->compile( 'access/main' );
$tpl->ins( 'main', $tpl->result( 'access/main' ) );
$tpl->clean( 'access/main' );