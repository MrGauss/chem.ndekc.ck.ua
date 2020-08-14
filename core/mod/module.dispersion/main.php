<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Лабораторія' ); }  

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'dispersion', 'view' );

$_dispersion = new dispersion;

$tpl->load( 'dispersion/main' );
                                           // array( 'is_dead' => 0, 'quantity_left:more' => 0 )
$tpl->set( '{list}', $_dispersion->get_html( array(  ), 'dispersion/line' ) );

$tpl->compile( 'dispersion/main' );

$tpl->ins( 'main', $tpl->result( 'dispersion/main' ) );
$tpl->clean( 'dispersion/main' );