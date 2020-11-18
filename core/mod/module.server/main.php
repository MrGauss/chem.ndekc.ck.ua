<?php

//////////////////////////////////////////////////////////////////////////////////////////

    if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
    if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Статистика серверу' ); }

    access::check( 'server', 'stats' );

    $skin = 'server/table_line';
    $i = 0;
    $cols = 2;

    foreach( get_loaded_extensions() as $extension )
    {
        if( $i > $cols ){ $i = 0; }
        if( $i == 0 ){ $tpl->load( $skin ); }

        $tpl->set( '{tag_'.$i.':name}',  $extension, $skin );
        $tpl->set( '{tag_'.$i.':value}', phpversion( $extension ), $skin );

        $i++;
        if( $i > $cols ){ $tpl->compile( $skin ); }
    }

    $extensions = $tpl->result( $skin );
    $extensions = preg_replace( '!\{tag_(\d+?):(name|value)\}!i', '', $extensions );

    $tpl->clean( $skin );

    $tpl->load( 'server/main' );

    $tpl->set( '{extensions}', $extensions );
    $tpl->set( '{tag:DOMAIN}', DOMAIN );
    $tpl->set( '{tag:os}', php_uname('s').' '.php_uname('r') );
    $tpl->set( '{tag:php_sapi_name}', php_sapi_name() );
    $tpl->set( '{tag:phpversion}', phpversion() );
    $tpl->set( '{tag:zend_version}', zend_version() );

    $tpl->set( '{tag:db:version}', $db->version() );
    $tpl->set( '{tag:db:size}', $db->dbsize() );
    $tpl->set( '{tag:db:name}', $db->get_info( 'name' ) );

    $tpl->set( '{tag:php:date_timezone}', common::db2html( ini_get('date.timezone') ) );
    $tpl->set( '{tag:php:default_charset}', common::db2html( ini_get('default_charset') ) );
    $tpl->set( '{tag:php:default_mimetype}', common::db2html( ini_get('default_mimetype') ) );
    $tpl->set( '{tag:php:max_file_uploads}', common::db2html( ini_get('max_file_uploads') ) );
    $tpl->set( '{tag:php:memory_limit}', common::db2html( ini_get('memory_limit') ) );
    $tpl->set( '{tag:php:max_execution_time}', common::db2html( ini_get('max_execution_time') ) );
    $tpl->set( '{tag:php:error_log}', common::db2html( preg_replace( '!'.addslashes(dirname(ROOT_DIR)).'!is', '', ini_get('error_log') ) ) );
    $tpl->set( '{tag:php:open_basedir}', common::db2html( preg_replace( '!'.addslashes(dirname(ROOT_DIR)).'!is', '', str_replace( PATH_SEPARATOR, "\n", ini_get('open_basedir') ) ) ) );
    $tpl->set( '{tag:php:display_errors}', (ini_get( 'display_errors' ))?'On':'Off' );

    foreach( $_SERVER as $k => $v )
    {
        $tpl->set( '{tag:server_'.strtolower($k).'}', common::db2html( $v ) );
    }

    foreach( array( 'nginx_access', 'nginx_error', 'php_error', 'postgresql', 'sql' ) as $log_file )
    {
        $log_file = LOGS_DIR.DS.$log_file.'.log';

        if( !file_exists($log_file) || !is_file($log_file ) ){ continue; }

        if( !is_readable( $log_file ) || ( $file_size = filesize($log_file) ) == 0  )
        {
            $tpl->set( '{log:'. basename($log_file) .'}', '' );
            $tpl->set( '{log:'. basename($log_file) .':mod}', '' );
            $tpl->set( '{log:'. basename($log_file) .':size}', '' );
            $tpl->set_block( '!\[log:'. basename($log_file) .'\](.+?)\[\/log\]!is', '' );
            continue;
        }

        $fopen   =   fopen( $log_file, 'rb' );
        $tpl->set( '{log:'. basename($log_file) .'}', common::db2html( fread( $fopen, $file_size ) ) );
                     fclose($fopen);

        $tpl->set( '{log:'. basename($log_file) .':mod}', date( 'Y.m.d H:i:s', filemtime($log_file) ) );
        $tpl->set( '{log:'. basename($log_file) .':size}', round( $file_size / 1024, 1 ).' kb' );
        $tpl->set_block( '!\[log:'. basename($log_file) .'\](.+?)\[\/log\]!is', '$1' );
    }

    $tpl->set_block( '!\{log:(.+?)\}!i', '' );

    $tpl->compile( 'server/main' );
    $tpl->ins( 'main', $tpl->result( 'server/main' ) );
    $tpl->clean( 'server/main' );