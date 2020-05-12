<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

access::check( 'admin', 'access' );

$tpl->load( 'access/main' );

$tpl->set( '{editor}', ( new access )->editor() );

$tpl->compile( 'access/main' );
$tpl->ins( 'main', $tpl->result( 'access/main' ) );
$tpl->clean( 'access/main' );