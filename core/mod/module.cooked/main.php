<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Приготування' ); }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'cooked', 'view' );

$cooked = new cooked;

$tpl->load( 'cooked/main' );
                                       // array( 'is_dead' => 0, 'quantity_left:more' => 0 )
$tpl->set( '{list}', $cooked->get_html( array(  ), 'cooked/line' ) );

$tpl->compile( 'cooked/main' );

$tpl->ins( 'main', $tpl->result( 'cooked/main' ) );
$tpl->clean( 'cooked/main' );