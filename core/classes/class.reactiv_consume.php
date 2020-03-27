<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class reactiv_consume
{
    use basic, spr, db_connect;

    public final function get_raw( $filters = array() )
    {
        $filters = is_array($filters) ? $filters : array();
        $WHERE = array();

        if( isset($filters['reactiv_hash']) )
        {
            $filters['reactiv_hash'] = common::filter_hash( $filters['reactiv_hash'] );
            $filters['reactiv_hash'] = is_array($filters['reactiv_hash']) ? $filters['reactiv_hash'] : array( $filters['reactiv_hash'] );
            $WHERE['reactiv_hash']   = 'reactiv.hash IN(\''. implode( '\', \'', array_values( $filters['reactiv_hash'] ) ) .'\')';
        }

        if( isset($filters['consume_hash']) )
        {
            $filters['consume_hash'] = common::filter_hash( $filters['consume_hash'] );
            $filters['consume_hash'] = is_array($filters['consume_hash']) ? $filters['consume_hash'] : array( $filters['consume_hash'] );
            $WHERE['consume_hash']   = 'reactiv_consume.hash IN(\''. implode( '\', \'', array_values( $filters['consume_hash'] ) ) .'\')';
        }
        else{ $WHERE['consume_hash']   = 'reactiv_consume.hash != \'\''; }

        if( isset($filters['using_hash']) )
        {
            $filters['using_hash'] = common::filter_hash( $filters['using_hash'] );
            $filters['using_hash'] = is_array($filters['using_hash']) ? $filters['using_hash'] : array( $filters['using_hash'] );
            $WHERE['using_hash']   = '"using".hash IN(\''. implode( '\', \'', array_values( $filters['using_hash'] ) ) .'\')';
        }

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        $SQL = '
            SELECT
                reactiv_consume.hash        as consume_hash,
                reactiv_consume.hash 	    as reactiv_hash,
                "using".hash 	            as using_hash,

                reactiv_consume.quantity,
                reactiv_consume.consume_ts  as consume_date,
                "using".date                as using_date,
                "using".purpose_id,

                reactiv.inc_date            as reactiv_inc_date,
                reactiv.dead_date           as reactiv_dead_date,
                reactiv.quantity_inc        as reactiv_quantity_inc,
                reactiv.quantity_left       as reactiv_quantity_left
            FROM
                reactiv_consume
                    LEFT JOIN "using" ON( "using".hash = reactiv_consume.using_hash )
                    LEFT JOIN reactiv ON( reactiv_consume.reactive_hash = reactiv.hash )
            '.$WHERE.';';

        $cache_var = 'reactiv_consume-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['consume_hash']] = $row;
        }
        return $data;
    }

}