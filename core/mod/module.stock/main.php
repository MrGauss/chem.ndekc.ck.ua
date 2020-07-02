<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'stock', 'view' );

$_stock = new stock;

$tpl->load( 'stock/main' );

$tpl->set( '{list}', $_stock->get_html( array( 'is_dead' => 0, 'quantity_left:more' => 0 ), 'stock/line' ) );

$tpl->compile( 'stock/main' );

$tpl->ins( 'main', $tpl->result( 'stock/main' ) );
$tpl->clean( 'stock/main' );