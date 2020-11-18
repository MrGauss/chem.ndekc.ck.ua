<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Використання' ); }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'using', 'view' );

//////////////////////////////////////////////////////////////////////////////////////////

$FILTERS = using::filters( $_POST );

$tpl->load( 'using/main' );

foreach( $FILTERS as $filter_name => $filter_value )
{
    if( is_array($filter_value) ){ continue; }
    $tpl->set( '{filter:'.$filter_name.'}', $filter_value );
}
$tpl->set( '{filter:using_date_from}',      $FILTERS['using_date']['from'] );
$tpl->set( '{filter:using_date_to}',        $FILTERS['using_date']['to'] );

$tpl->set( '{list}', (new using)->get_html( $FILTERS , 'using/line' ) );

$tpl->compile( 'using/main' );
$tpl->ins( 'main', $tpl->result( 'using/main' ) );
$tpl->clean( 'using/main' );