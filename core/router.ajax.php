<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$rfile = MODS_DIR.DS.'module.'._MOD_.''.DS.'ajax'.DS.'main.php';

if( defined( 'CURRENT_USER_ID' ) && CURRENT_USER_ID )
{
    if( !file_exists($rfile) )
    {
            if( !is_dir( dirname( dirname($rfile) ) ) ){ mkdir( dirname( dirname( $rfile ) ) ); }
            if( !is_dir( dirname($rfile) ) ){ mkdir( dirname( $rfile ) ); }
            fclose( fopen( $rfile, 'w' ) );
            ajax::set_error( 1, 'File "'.$rfile.'" not exist!' );
    }
    else
    {
        $_REQUEST = common::utf2win( $_REQUEST );
        $_POST    = common::utf2win( $_POST );

        require( $rfile );
    }
}
else
{
    ajax::set_error( 8, 'USER NOT FOUND!' );
}

echo ajax::result();
exit;

