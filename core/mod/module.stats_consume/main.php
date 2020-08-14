<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Статистика' ); }

//////////////////////////////////////////////////////////////////////////////////////////

$_POST['consume_date'] = isset($_POST['consume_date']) && is_array($_POST['consume_date']) ? $_POST['consume_date'] : array();
$_POST['consume_date'][0] = isset($_POST['consume_date'][0]) ? $_POST['consume_date'][0] : '01.01.'.date('Y');
$_POST['consume_date'][1] = isset($_POST['consume_date'][1]) ? $_POST['consume_date'][1] : '31.12.'.date('Y');

$_POST['consume_date'][0] = strtotime( $_POST['consume_date'][0] );
$_POST['consume_date'][1] = strtotime( $_POST['consume_date'][1] );

sort( $_POST['consume_date'] );

$_POST['consume_date'][0] = date( 'd.m.Y', $_POST['consume_date'][0] );
$_POST['consume_date'][1] = date( 'd.m.Y', $_POST['consume_date'][1] );


access::check( 'stats', 'view' );

$_stats = new stats;
$tpl->load( 'stats_consume/main' );

$tpl->set( '{consume_date:from}', $_POST['consume_date'][0] );
$tpl->set( '{consume_date:to}', $_POST['consume_date'][1] );


$tpl->set( '{table01}', $_stats->get_stats_consume_by_stock_id_html( array( 'consume_date:from' => $_POST['consume_date'][0], 'consume_date:to' => $_POST['consume_date'][1], ) ) );
$tpl->set( '{table02}', $_stats->get_stats_consume_by_reagent_id_html( array( 'consume_date:from' => $_POST['consume_date'][0], 'consume_date:to' => $_POST['consume_date'][1], ) ) );
$tpl->set( '{table03}', $_stats->get_stats_consume_by_purpose_id_html( array( 'consume_date:from' => $_POST['consume_date'][0], 'consume_date:to' => $_POST['consume_date'][1], ) ) );
$tpl->compile( 'stats_consume/main' );
$tpl->ins( 'main', $tpl->result( 'stats_consume/main' ) );
$tpl->clean( 'stats_consume/main' );