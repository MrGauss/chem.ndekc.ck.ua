<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Склад' ); }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'stock', 'view' );

$_stock = new stock;

$tpl->load( 'stock/main' );
                                       // array( 'is_dead' => 0, 'quantity_left:more' => 0 )
$tpl->set( '{list}', $_stock->get_html( array() , 'stock/line' ) );

$tpl->compile( 'stock/main' );

$tpl->ins( 'main', $tpl->result( 'stock/main' ) );
$tpl->clean( 'stock/main' );