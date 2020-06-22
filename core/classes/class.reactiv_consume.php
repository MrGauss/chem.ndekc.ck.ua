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

    public final function save( $data = array() )
    {
        $time_minimal = time() - ( 60*60*24*365*10 );

        $data2db =  array(
                        'reactiv_hash'  => common::filter_hash(     isset($data['reactiv_hash'])  ? $data['reactiv_hash']   : false ),
                        'quantity'      => common::float(           isset($data['quantity'])      ? $data['quantity']       : false ),
                        'inc_expert_id' => common::integer(         isset($data['inc_expert_id']) ? $data['inc_expert_id']  : false ),
                        'date'          => isset($data['date']) ? common::en_date( $data['date'], 'Y-m-d' ) : false,
                    );
        $hash = isset($data['hash']) ? common::filter_hash( $data['hash'] ) : false;

        if( !$data2db['reactiv_hash'] ) { return self::error( 'Розчин не знайдено в лабораторії!' ); }
        if( !$data2db['quantity'] )     { return self::error( 'Не зазначена кількість використаного розчину!' ); }
        if( !$data2db['inc_expert_id'] ){ return self::error( 'Не вказано хто використовував розчин!' ); }
        if( strtotime($data2db['date']) > time() ){ return self::error( 'Не можна використовувати розчин в майбутньому!', 'inc_date' ); }
        if( strtotime($data2db['date']) < $time_minimal ){ return self::error( 'Не можна використати розчин в таку сиву давнину!', 'inc_date' ); }


        $data2db = array_map( array( $this->db, 'safesql' ), $data2db );

        if( !$hash )
        {
            $query = 'INSERT INTO reactiv_consume '.db::array2ins( $data2db ).' RETURNING hash;';
        }
        else
        {
            $query = 'UPDATE reactiv_consume SET '.db::array2upd( $data2db ).' WHERE hash = \''.$this->db->safesql( $hash ).'\' RETURNING hash;';
        }

        $hash = $this->db->super_query( $query );

        if( is_array($hash) && isset($hash['hash']) ){ $hash = $hash['hash']; }
        else{ $hash = false; }

        return $hash;
    }

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
                reactiv.hash 	            as reactiv_hash,
                "using".hash 	            as using_hash,

                reactiv_consume.quantity,
                reactiv_consume.consume_ts  as consume_date,

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
            $row['consume_hash'] = common::filter_hash( $row['consume_hash'] );
            $data[$row['consume_hash']] = $row;
        }
        return $data;
    }

}