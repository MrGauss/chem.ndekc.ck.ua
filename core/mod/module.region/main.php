<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Редактор регіонів' ); }

access::check( 'admin', 'region_edit' );