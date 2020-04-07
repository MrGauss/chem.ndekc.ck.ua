<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class consume
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
            $WHERE['consume_hash']   = 'consume.hash IN(\''. implode( '\', \'', array_values( $filters['consume_hash'] ) ) .'\')';
        }
        else{ $WHERE['consume_hash']   = 'consume.hash != \'\''; }

        if( isset($filters['using_hash']) )
        {
            $filters['using_hash'] = common::filter_hash( $filters['using_hash'] );
            $filters['using_hash'] = is_array($filters['using_hash']) ? $filters['using_hash'] : array( $filters['using_hash'] );
            $WHERE['using_hash']   = '"using".hash IN(\''. implode( '\', \'', array_values( $filters['using_hash'] ) ) .'\')';
        }

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        $SQL = '
            SELECT
                reactiv.hash 	as reactiv_hash,
                consume.hash    as consume_hash,
                "using".hash 	as using_hash,
                consume.quantity,
                consume.dispersion_id,
                consume.consume_ts,
                consume.date    as consume_date,
                "using".date    as using_date,
                "using".purpose_id,
                dispersion.inc_date as dispersion_inc_date,
                dispersion.quantity_left as dispersion_quantity_left,
                dispersion.quantity_inc as dispersion_quantity_inc,
                stock.reagent_id,
                stock.reagent_number
            FROM
                consume
                    RIGHT JOIN dispersion ON( dispersion.id = consume.dispersion_id )
                    RIGHT JOIN stock ON( stock.id = dispersion.stock_id )
                    LEFT JOIN "using" ON( "using".hash = consume.using_hash )
                    LEFT JOIN reactiv ON( "using".hash = reactiv.using_hash )
            '.$WHERE.';';

        // echo $SQL;exit;

        $cache_var = 'consume-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['consume_hash'] = common::filter_hash( $row['consume_hash'] ? $row['consume_hash'] : '' );
            $row['reactiv_hash'] = common::filter_hash( $row['reactiv_hash'] ? $row['reactiv_hash'] : '' );
            $row['using_hash']   = common::filter_hash( $row['using_hash'] ? $row['using_hash'] : '' );
            
            $data[$row['consume_hash']] = $row;
        }
        return $data;
    }

}