<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

class err_handler
{
    static public final function start()
    {
        set_error_handler( 'err_handler::error', E_ALL );
        register_shutdown_function( array( 'err_handler', 'process' ) );
    }

    static public final function error( $errcode, $errstr, $errfile, $errline )
    {
            ob_end_clean();
            self::show( self::get_text_from_level($errcode), str_replace( ROOT_DIR, '', $errstr ), str_replace( ROOT_DIR, '', $errfile ), $errline );
            exit;
    }

    static public final function process()
    {
        $error = error_get_last();

        if( is_array($error) && count($error) )
        {
            ob_end_clean();
            self::show( self::get_text_from_level( $error['type'] ), str_replace( ROOT_DIR, '', $error['message'] ), str_replace( ROOT_DIR, '', $error['file'] ), $error['line'] );
            exit;
        }
    }

    static public final function get_text_from_level( $code )
    {
        if($code == E_ERROR ){ return 'E_ERROR'; }
        if($code == E_WARNING ){ return 'E_WARNING'; }
        if($code == E_PARSE ){ return 'E_PARSE'; }
        if($code == E_NOTICE ){ return 'E_NOTICE'; }
        if($code == E_CORE_ERROR ){ return 'E_CORE_ERROR'; }
        if($code == E_CORE_WARNING ){ return 'E_CORE_WARNING'; }
        if($code == E_COMPILE_ERROR ){ return 'E_COMPILE_ERROR'; }
        if($code == E_COMPILE_WARNING ){ return 'E_COMPILE_WARNING'; }
        if($code == E_USER_ERROR ){ return 'E_USER_ERROR'; }
        if($code == E_USER_WARNING ){ return 'E_USER_WARNING'; }
        if($code == E_USER_NOTICE ){ return 'E_USER_NOTICE'; }
        if($code == E_STRICT ){ return 'E_STRICT'; }
        if($code == E_RECOVERABLE_ERROR ){ return 'E_RECOVERABLE_ERROR'; }
        if($code == E_DEPRECATED ){ return 'E_DEPRECATED'; }
        if($code == E_USER_DEPRECATED ){ return 'E_USER_DEPRECATED'; }
        if($code == E_ALL ){ return 'E_ALL'; }
        return 'FUCKING_SHIT';
    }

    static public final function show( $errcode, $errstr, $errfile, $errline )
    {
        header( 'Content-type: text/html; charset='.CHARSET );
        echo ''.$errcode.' ERROR: '.$errstr."\n\t".'FILE: '.$errfile.''."\n\t".'LINE: '.$errline;
    }
}

