<?php

error_reporting ( E_ALL );
ini_set ( 'display_errors', true );
ini_set ( 'html_errors', false );
ini_set ( 'error_reporting', E_ALL );
ini_set ( 'max_execution_time', 60 );

//////////////////////////////////////////////////////////////////////////////////////////

define ( 'DOMAIN',          strtolower( $_SERVER['Host'] ) );
define ( 'TESTING_MODE',    ( strpos( DOMAIN, 'test' ) !== false ) ? true : false );
define ( 'HOME',            '/' );
define ( 'HOMEURL',        'https://'.DOMAIN.HOME );
define ( 'MRGAUSS',         true );
define ( 'DS',              DIRECTORY_SEPARATOR );
define ( 'ROOT_DIR',        dirname ( __FILE__ ) );
define ( 'CORE_DIR',        ROOT_DIR.DS.'core' );
define ( 'CLASSES_DIR',     CORE_DIR.DS.'classes' );
define ( 'CACHE_DIR',       ROOT_DIR.DS.'.cache' );
define ( 'MODS_DIR',        CORE_DIR.DS.'mod' );
define ( 'CURRENT_SKIN',    ROOT_DIR.DS.'res' );
define ( 'TPL_DIR',         CURRENT_SKIN.DS.'tpl' );
define ( 'USER_IP',         $_SERVER['REMOTE_ADDR'] );
define ( 'CHARSET',         'CP1251' );
define ( 'ENCODING',        'Windows-1251' );
define ( 'CACHE_TYPE',      'FILE' );
define ( 'LOGS_DIR',        dirname( ROOT_DIR ).DS.'log' );
define ( 'TEMP_DIR',        dirname( ROOT_DIR ).DS.'tmp' );
define ( 'DYNAMIC_SALT',    md5( date('Y.m.d') . sha1( DOMAIN ) . USER_IP ) );

//////////////////////////////////////////////////////////////////////////////////////////

ob_start();
header( 'Content-type: text/html; charset='.CHARSET );

//////////////////////////////////////////////////////////////////////////////////////////

require( CLASSES_DIR.DS.'class.err_handler.php' );
err_handler::start();

//////////////////////////////////////////////////////////////////////////////////////////

require( CORE_DIR.DS.'init.php' );

//////////////////////////////////////////////////////////////////////////////////////////

$tpl->load( 'content' );

if( defined('_MOD_NAME_') && _MOD_NAME_ )
{
    $tpl->set( '[modinfo]', '' );
    $tpl->set( '[/modinfo]', '' );
    $tpl->set( '{mod:name}', _MOD_NAME_ );
    $tpl->set( '{mod:area}', _MOD_ );
    $tpl->set( '{mod:link}', HOME.'index.php?mod='._MOD_ );
}
else
{
    $tpl->set_block( '!\[modinfo\](.+?)\[\/modinfo\]!is', '' );
}

$tpl->compile( 'content' );

//////////////////////////////////////////////////////////////////////////////////////////

echo strtr( $tpl->result( 'content' ), array
(
    '{user_memory}' => round(memory_get_peak_usage()/1024,2).' kb',
    '{queries}' => isset($db->counters['queries'])?$db->counters['queries']:0,
    '{queries_cached}' => isset($db->counters['cached'])?$db->counters['cached']:0,
) );



exit;