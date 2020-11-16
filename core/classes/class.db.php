<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

define( 'QUERY_CACHABLE', ' -- %QUERY_CACHABLE' );

class db
{
    const CACHED = '--CACHED';
    private $db_id = false;
    private $query_id = false;
    private $connected = false;
    private $is_transaction = false;

    private $_DBHOST = false;
    private $_DBNAME = false;
    private $_DBPORT = false;
    private $_DBUSER = false;
    private $_DBPASS = false;
    private $_SCHEMA = false;
    private $_COLLATE = false;
    private $_CHARSET = false;

    public  $counters = array();
    public  $version = false;

    public final function __construct( $dbhost=false, $dbport = false, $dbname=false, $dbuser=false, $dbpass=false, $schema=false, $charset=false, $collate=false )
    {
        $this->_DBHOST  = $dbhost;
        $this->_DBPORT  = $dbport;
        $this->_DBNAME  = $dbname;
        $this->_DBUSER  = $dbuser;
        $this->_DBPASS  = $dbpass;
        $this->_COLLATE = $collate;
        $this->_CHARSET = $charset;
        $this->_SCHEMA  = $schema;

        $this->connect();

        $this->version = pg_version();
        $this->version = $this->version['server'];
    }

    public final function get_info( $param )
    {
        if( $param == 'host' ){ return $this->_DBHOST; }
        if( $param == 'name' ){ return $this->_DBNAME; }
        if( $param == 'user' ){ return $this->_DBUSER; }
        if( $param == 'collate' ){ return $this->_COLLATE; }
        if( $param == 'charset' ){ return $this->_CHARSET; }
        return false;
    }

    public final function __destruct()
    {
        if( $this->is_transaction ){ $this->transaction_rollback(); }
        $this->close();
    }

    public final function close()
    {
        if( $this->connected )
        {
            pg_close( $this->db_id );
        }
    }

    public function connect()
    {
        $this->db_id = pg_connect ('host='.$this->_DBHOST.' port='.$this->_DBPORT.' dbname='.$this->_DBNAME.' user='.$this->_DBUSER.' password='.$this->_DBPASS);

        if( !$this->db_id || pg_connection_status( $this->db_id ) !== PGSQL_CONNECTION_OK )
        {
            self::show_error('bad connection!');
        }
        else
        {
            $this->connected = true;
        }

        pg_query( $this->db_id, 'SET CLIENT_ENCODING TO \''.$this->_COLLATE.'\';');
        pg_query( $this->db_id, 'SET NAMES \''.$this->_COLLATE.'\';');
        pg_query( $this->db_id, 'SET search_path TO '.$this->_SCHEMA.', pg_catalog;');
        pg_query( $this->db_id, 'SET TIME ZONE \'EET\';');

        pg_set_client_encoding( $this->db_id, $this->_COLLATE );
    }

    public final function safesql( $source )
    {
        if( $this->db_id ){ return pg_escape_string($this->db_id, $source ); }
        return pg_escape_string( $source );
    }


    public final function transaction_start()
    {
        if( $this->is_transaction ){ common::err( 'TRANSACTION IS ALREADY STARTED!' ); }

        $this->query( 'BEGIN;' );
        $this->is_transaction = true;
        return true;
    }

    public final function transaction_commit()
    {
        if( !$this->is_transaction ){ return false; }

        $this->query( 'COMMIT;' );
        $this->is_transaction = false;
        return true;
    }

    public final function transaction_rollback( $point = false )
    {
        if( !$this->is_transaction ){ return false; }

        $this->query( 'ROLLBACK'.($point?(' TO SAVEPONT_'.md5( $point )):'').';' );
        if( !$point ){ $this->is_transaction = false;  }
        return true;
    }

    public final function transaction_save( $point = false )
    {
        if( !$this->is_transaction ){ return false; }

        $this->query( 'SAVEPOINT SAVEPONT_'.md5( $point ).';' );
        return true;
    }


    public final function query( $SQL )
    {
        if( !$this->connected || !$this->db_id || !pg_ping($this->db_id) ){ $this->connect(); }

        $this->query_id = pg_query( $this->db_id, $SQL );

        self::log( $SQL );

        if( !isset($this->counters['queries']) ){ $this->counters['queries'] = 0; }
        if( !isset($this->counters['cached']) ){ $this->counters['cached'] = 0; }

        $this->counters['queries']++;

        if( strpos( $SQL, self::CACHED ) !== false ){ $this->counters['cached']++; }

        if( $error = pg_last_error() )
        {
            self::show_error( $error );
        }

        return $this->query_id;
    }

    public final function get_row( $query_id = false )
    {
        if( !$query_id ){ $query_id = $this->query_id; }
        if( !$query_id ){ return false; }
        return pg_fetch_assoc( $query_id );
    }

    public final function get_query_rows( $query_id = false )
    {
        if( !$query_id ){ $query_id = &$this->query_id; }
        if( !$query_id ){ return false; }
        return abs( intval( pg_num_rows( $query_id ) ) );
    }

    public final function super_query( $query )
    {
        $rows = array();
        $qid = $this->query( $query );

        while($row = $this->get_row( $qid ))
        {
            $rows[] = $row;
        }
        $this->free( $qid );

        if( !count($rows) ){ $rows = array(); }
        if( count($rows) == 1 ){ $rows = $rows[0]; }

        return $rows;
    }

    public final function get_count( $query )
    {
        $count = $this->super_query($query);
        return abs(intval( isset($count['count'])?$count['count']:0 ));
    }

    public final function free( $query_id = '' )
    {
        if ( $query_id == '' ){ $query_id = &$this->query_id; }
        pg_free_result($query_id);
    }

    static private function show_error( $error )
    {
        echo $error;
        exit;
    }

    private static function log( $SQL )
    {
        $file = CACHE_DIR.DS.'sql_log-'.date('Y.m.d').'.log';

        $SQL =
                 "-------------------------\n"
                ."-- ".date('Y.m.d H:i:s')." --\n"
                . $SQL
                ."\n-------------------------"
                ."\n\n";

        $fop =  fopen( $file, 'a' );

        $i = 0;

        while( true )
        {
            if( $i > 10 ){ common::err( 'CAN NOT LOCK FILE "'.$file.'"!' ); exit; }
            if( !flock($fop, LOCK_EX ) )
            {
                usleep( 10 );
                $i++;
                continue;
            }
            fwrite( $fop, $SQL );
            fflush( $fop );
            flock( $fop, LOCK_UN );

            break;
        }

        fclose( $fop );

        return true;

    }

    public function version()
    {
        $SQL = 'SHOW server_version;';
        $SQL = $this->super_query( $SQL );
        return $SQL['server_version'];
    }

    public function dbsize()
    {
        $SQL = 'SELECT pg_size_pretty(pg_database_size(\''.$this->_DBNAME.'\')) as size;';
        $SQL = $this->super_query( $SQL );
        return $SQL['size'];
    }

    static public final function array2upd( $array )
    {
        foreach( $array as $k=>$v )
        {
            $array[$k] = '"'.$k.'" = \''.$v.'\'';
        }
        return implode( ', ', $array );

    }
    static public final function array2ins( $array )
    {
        return '("'.implode('", "', array_keys($array)).'") VALUES ( \''.implode( '\', \'', array_values($array) ).'\' )';
    }
}

