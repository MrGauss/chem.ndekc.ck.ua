<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class autocomplete
{
    use basic, spr, db_connect;

    static public final function check_key( $key, $table, $column )
    {
        return ( $key && self::key( $table, $column ) == $key ) ? true : false;
    }

    static public final function key( $table, $column )
    {
        return common::hash( CURRENT_USER_ID . common::encode_string( $table . $column ) . CURRENT_REGION_ID .common::hash(  date( 'Y-m-d' ) ) );
    }


    static public final function make( $table, $column, $term, $top10 = false )
    {
        $table  = common::filter( $table );
        $column = common::filter( $column );
        $term   = common::filter( $term );
        $top10  = $top10 ? true : false;

        if( !$top10 && ( !$term || strlen( $term ) < 3 ) ){ return false; }
        if( !$column )  { return false; }
        if( !$table )   { return false; }

        $obj = new self;

        $table_info = $obj->get_table_info( $table );

        if( !array_key_exists( $column, $table_info ) || !isset($table_info[$column]['data_type']) ){ return fasle; }

        $data = $obj->search( $table, $column, $term, $top10 );

        return $data;
    }

    private final function search( $table, $column, $term, $top10 = false )
    {
        $table  = preg_replace( '!(\W+)!is', '', common::filter( $table ) );
        $column = preg_replace( '!(\W+)!is', '', common::filter( $column ) );
        $term   = common::strtolower( common::filter( $term ) );

        $SQL = '
            SELECT
                DISTINCT "'.$table.'"."'.$column.'" as "result"
            FROM
                '.$table.'
            WHERE
                lower("'.$table.'"."'.$column.'") LIKE \''.$this->db->safesql($term).'%\'
            ORDER BY "'.$table.'"."'.$column.'" ASC
            LIMIT 20
            OFFSET 0;
        ';

        $SQL = $this->db->query( $SQL );
        $data = array();

        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $data[] = array( 'value' => $row['result'], 'label' => $row['result'] );
        }

        return $data;
    }

    private final function get_table_info( $table )
    {
        $SQL = 'SELECT
                    column_name,
                    data_type,
                    udt_name,
                    character_maximum_length
                FROM
                    INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = \''.$this->db->safesql( $table ).'\';'.db::CACHED;

        $cache_var = 'spr-tableinfo-'.$table;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }

        $SQL = $this->db->query( $SQL );

        $data = array();
        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $row['character_maximum_length'] = common::integer( $row['character_maximum_length'] );
            $data[$row['column_name']] = $row;
        }

        $SQL = '
            SELECT
                    tc.table_name,
                    kcu.column_name,
                    ccu.table_schema AS foreign_table_schema,
                    ccu.table_name AS foreign_table_name,
                    ccu.column_name AS foreign_column_name
            FROM
                    information_schema.table_constraints AS tc
                    JOIN information_schema.key_column_usage AS kcu
                        ON tc.constraint_name = kcu.constraint_name
                        AND tc.table_schema = kcu.table_schema
                    JOIN information_schema.constraint_column_usage AS ccu
                        ON ccu.constraint_name = tc.constraint_name
                        AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = \'FOREIGN KEY\' AND ccu.table_name=\''.$this->db->safesql($table).'\';
        ';
        $SQL = $this->db->query( $SQL );
        $data['foreign'] = array();
        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $data['foreign'][] = $row;
        }

        $this->db->free();

        cache::set( $cache_var, $data );
        return $data;
    }

}