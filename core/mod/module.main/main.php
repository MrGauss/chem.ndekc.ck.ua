<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

$tpl->load( 'mainlist' );
$tpl->compile( 'mainlist' );
$tpl->ins( 'main', $tpl->result( 'mainlist' ) );
$tpl->clean( 'mainlist' );