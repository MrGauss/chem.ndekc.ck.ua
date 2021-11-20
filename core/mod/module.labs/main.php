<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Редактор лабораторій' ); }

access::check( 'admin', 'lab_edit' );