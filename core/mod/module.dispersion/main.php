<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'dispersion', 'view' );

$_dispersion = new dispersion;

$tpl->load( 'dispersion/main' );

$tpl->set( '{list}', $_dispersion->get_html( array(), 'dispersion/line' ) );

$tpl->compile( 'dispersion/main' );

$tpl->ins( 'main', $tpl->result( 'dispersion/main' ) );
$tpl->clean( 'dispersion/main' );