<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$_dispersion = new cooked;

$tpl->load( 'cooked/main' );

$tpl->set( '{list}', $_dispersion->get_html( array(), 'cooked/line' ) );

$tpl->compile( 'cooked/main' );

$tpl->ins( 'main', $tpl->result( 'cooked/main' ) );
$tpl->clean( 'cooked/main' );