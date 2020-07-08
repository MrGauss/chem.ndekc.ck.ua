<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

require( CLASSES_DIR.DS.'class.test.php' );

cache::clean();

/*
$purpose        = ( new spr_manager( 'purpose' ) )  ->get_raw();
$units          = ( new spr_manager( 'units' ) )    ->get_raw();
$reagent        = ( new spr_manager( 'reagent' ) )  ->get_raw();
$reactiv_menu   = ( new recipes )                   ->get_raw();
*/

// CURRENT_GROUP_ID
// CURRENT_USER_ID

// CREATE REAGENTS //
$test = new test;
//$test->create_reagent();    cache::clean();
//$test->create_recipe();     cache::clean();
//$test->create_stock();      cache::clean();
//$test->create_dispersion(); cache::clean();
$test->create_using();      cache::clean();


