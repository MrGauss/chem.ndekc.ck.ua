<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) ){ require( CLASSES_DIR.DS.'trait.basic.php' ); }

//////////////////////////////////////////////////////////////////////////////////////////

class cache
{
    use basic;
    const CACHE_TYPE = 'serialize'; // raw

    static public final function mem_init( $server, $port )
    {
        if( isset($GLOBALS['_MEMCACHE']) && is_object($GLOBALS['_MEMCACHE']) )
        {
            $GLOBALS['_MEMCACHE']->close();
        }

        $GLOBALS['_MEMCACHE'] = false;
        $GLOBALS['_MEMCACHE'] = new Memcached();
        $GLOBALS['_MEMCACHE']->addServer( $server, $port );
    }

    static public final function clean( $prefix = false )
    {
        $prefix = self::strtolower( $prefix );

        $cache_dir = opendir( CACHE_DIR );

        while( ($file = readdir($cache_dir)) !== false )
        {
            if( is_file( CACHE_DIR.DS.$file ) === false ){ continue; }

            if( $prefix )
            {
                if( strpos( $file, 'cache-'.$prefix ) !== false && strpos( $file, '[G-'.CURRENT_GROUP_ID.']' ) !== false )
                {
                    fclose( fopen( CACHE_DIR.DS.$file, 'w' ) );
                    unlink( CACHE_DIR.DS.$file );
                }
            }
            else
            {
                fclose( fopen( CACHE_DIR.DS.$file, 'w' ) );
                unlink( CACHE_DIR.DS.$file );
            }

        }

        closedir($cache_dir);

        return true;
    }

    static public final function set( $name, $data, $log = false, $comment = false )
    {
        $name = self::get_cache_file_path( $name );

        if( self::CACHE_TYPE == 'serialize' )
        {
            $data = serialize( $data );
        }
        else if( self::CACHE_TYPE == 'raw' )
        {
            $data = '<?php if( !defined(\'MRGAUSS\') ){ echo basename(__FILE__); exit; }'."\n".' // CACHE CREATED: '.microtime(true).' ('.date('Y-m-d H:i:s').') '."\n".'return '.var_export( $data, true ).'; '."\n".'// COMMENT: '.$comment.' '."\n";
        }

        return self::write( $name, $data, $log );
    }

    static public final function get( $name )
    {
        //return false;
        $name = self::get_cache_file_path( $name );

        if( !file_exists($name) ){ return false; }

        $ftime = filemtime($name);

        if( $ftime < ( time()-60*60 ) )
        {
            unlink( $name );
            return false;
        }

        if( self::CACHE_TYPE == 'serialize' )
        {
            $data = unserialize( file_get_contents($name) );
            if( $data ){return $data; }
            return false;
        }
        else if( self::CACHE_TYPE == 'raw' )
        {
            return require( $name );
        }
    }

    static public final function write( $filename, $data = false )
    {
            fclose( fopen( $filename, 'a' ) );

            $fop =  fopen( $filename, 'r+' );

            $i = 0;

            while( true )
            {
                if( $i > 10 ){ common::err( 'CAN NOT LOCK FILE "'.$filename.'"!' ); exit; }
                if( !flock($fop, LOCK_EX ) )
                {
                    usleep( 10 );
                    $i++;
                    continue;
                }

                ftruncate($fop, 0);
                fwrite( $fop, $data );
                fflush( $fop );
                flock( $fop, LOCK_UN );

                break;
            }

            fclose( $fop );

            return true;
    }

    static private final function get_cache_file_path( $name )
    {
        return CACHE_DIR.DS.'cache-'.self::strtolower( trim( $name ) ).'.[G-'.CURRENT_GROUP_ID.']['.self::CACHE_TYPE.'].php';
    }
}

//////////////////////////////////////////////////////////////////////////////////////////

$_MEMCACHE = false;

if( defined('CACHE_TYPE') && CACHE_TYPE == 'MEM' )
{
    // cache::mem_init( 'unix:/var/run/memcached.sock', 0 );
}

//////////////////////////////////////////////////////////////////////////////////////////

