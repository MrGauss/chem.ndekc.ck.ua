<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$load_module      = MODS_DIR.DS.'module.'._MOD_.DS.'main.php';

$_needed_files = array();
$_needed_files[] = $load_module;
$_needed_files[] = MODS_DIR.DS.'module.'._MOD_.DS.'ajax'.DS.'main.php';
$_needed_files[] = CURRENT_SKIN.DS.'css'.DS.'chem.'._MOD_.'.css';
$_needed_files[] = CURRENT_SKIN.DS.'js'.DS.'chem.'._MOD_.'.js';
$_needed_files[] = CURRENT_SKIN.DS.'tpl'.DS._MOD_.DS.'main.tpl';

var_export($_needed_files);exit;

foreach( $_needed_files as $_file )
{
    if( !file_exists( $_file ) )
    {
        if( !is_dir( dirname($_file) ) )
        {
            mkdir( dirname( $_file ) );
        }
        fclose( fopen( $_file, 'w' ) );
    }
}


if( !file_exists( $load_module ) )
{
    if( !is_dir( dirname($load_module) ) )
    {
        mkdir( dirname( $load_module ) );
    }
    fclose( fopen( $load_module, 'w' ) );
}

if( !file_exists( $load_module_ajax ) )
{
    if( !is_dir( dirname($load_module_ajax) ) )
    {
        mkdir( dirname( $load_module_ajax ) );
    }
    fclose( fopen( $load_module_ajax, 'w' ) );
}

require( $load_module );

