<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'dispersion', 'view' );

$_dispersion = new dispersion;

$tpl->load( 'dispersion/main' );

$tpl->set( '{list}', $_dispersion->get_html( array( 'is_dead' => 0, 'quantity_left:more' => 0 ), 'dispersion/line' ) );

$tpl->compile( 'dispersion/main' );

$tpl->ins( 'main', $tpl->result( 'dispersion/main' ) );
$tpl->clean( 'dispersion/main' );