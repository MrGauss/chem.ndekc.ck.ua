<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$_stock = new stock;

$tpl->load( 'stock/main' );

$tpl->set( '{list}', $_stock->get_html( array(), 'stock/line' ) );

$tpl->compile( 'stock/main' );

$tpl->ins( 'main', $tpl->result( 'stock/main' ) );
$tpl->clean( 'stock/main' );