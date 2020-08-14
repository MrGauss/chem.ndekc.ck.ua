<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', false ); }

$tpl->load( 'mainlist' );
$tpl->compile( 'mainlist' );
$tpl->ins( 'main', $tpl->result( 'mainlist' ) );
$tpl->clean( 'mainlist' );