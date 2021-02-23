<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Статистика' ); }

//////////////////////////////////////////////////////////////////////////////////////////

$_POST['is_precursor']  = ( isset($_POST['is_precursor']) ? common::integer( $_POST['is_precursor'] ) : 0 );
$_POST['by_region'] = ( isset($_POST['by_region']) ? common::integer( $_POST['by_region'] ) : 0 );

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

$tpl->set( '{consume_date:from}',   $_POST['consume_date'][0] );
$tpl->set( '{consume_date:to}',     $_POST['consume_date'][1] );

$tpl->set( '{is_precursor}',        $_POST['is_precursor'] ? 'checked="checked"' : '' );
$tpl->set( '{by_region}',           $_POST['by_region'] ? 'checked="checked"' : '' );

$FILTERS = array
(
    'consume_date:from'     => $_POST['consume_date'][0],
    'consume_date:to'       => $_POST['consume_date'][1],
    'precursor_only'        => $_POST['is_precursor'],
    'by_region'             => $_POST['by_region'],
);

$tpl->set( '{table01}', $_stats->get_stats_consume_by_stock_id_html(   $FILTERS ) );
$tpl->set( '{table02}', $_stats->get_stats_consume_by_reagent_id_html( $FILTERS ) );
$tpl->set( '{table03}', $_stats->get_stats_consume_by_purpose_id_html( $FILTERS ) );
$tpl->compile( 'stats_consume/main' );
$tpl->ins( 'main', $tpl->result( 'stats_consume/main' ) );
$tpl->clean( 'stats_consume/main' );