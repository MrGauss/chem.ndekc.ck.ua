<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

/*$_POST['consume_date'] = isset($_POST['consume_date']) && is_array($_POST['consume_date']) ? $_POST['consume_date'] : array();
$_POST['consume_date'][0] = isset($_POST['consume_date'][0]) ? $_POST['consume_date'][0] : '01.01.'.date('Y');
$_POST['consume_date'][1] = isset($_POST['consume_date'][1]) ? $_POST['consume_date'][1] : '31.12.'.date('Y');

$_POST['consume_date'][0] = strtotime( $_POST['consume_date'][0] );
$_POST['consume_date'][1] = strtotime( $_POST['consume_date'][1] );

sort( $_POST['consume_date'] );

$_POST['consume_date'][0] = date( 'd.m.Y', $_POST['consume_date'][0] );
$_POST['consume_date'][1] = date( 'd.m.Y', $_POST['consume_date'][1] ); */


access::check( 'stats', 'view' );

$curr_main_skin = _MOD_.'/main';
$_stats = new stats;
$tpl->load( $curr_main_skin );

//$tpl->set( '{consume_date:from}', $_POST['consume_date'][0] );
//$tpl->set( '{consume_date:to}', $_POST['consume_date'][1] );


$tpl->set( '{table01}', $_stats->get_stats_consume_dynamics_html( array() ) );


$tpl->compile( $curr_main_skin );
$tpl->ins( 'main', $tpl->result( $curr_main_skin ) );
$tpl->clean( $curr_main_skin );