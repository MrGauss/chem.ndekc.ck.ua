<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$spr = new spr_manager('reagent_state');

$tpl->load( _MOD_.'/main' );

$tpl->set( '{list}', $spr->get_html( array(),  _MOD_.'/line' ) );

$tpl->compile(  _MOD_.'/main' );

$tpl->ins( 'main', $tpl->result(  _MOD_.'/main' ) );
$tpl->clean(  _MOD_.'/main' );