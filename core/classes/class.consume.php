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

    public final function save( $data = array() )
    {
        $data2db = array(
            'dispersion_id' => common::integer( isset($data['dispersion_id'])?$data['dispersion_id']:false ),
            'quantity'      => common::numeric(  isset($data['quantity'])?$data['quantity']:false ),
            'inc_expert_id' => common::integer( isset($data['inc_expert_id'])?$data['inc_expert_id']:false ),
            'date'          => isset($data['date'])? common::en_date( $data['date'], 'Y-m-d' ) : false,
        );
        $hash = isset($data['hash']) ? common::filter_hash( $data['hash'] ) : false;
        $time_minimal = time() - ( 60*60*24*365*10 );
        $data['utilisation'] = ( isset( $data['utilisation'] ) && $data['utilisation'] ) ? true : false;

        if( !$data2db['dispersion_id'] ){ return self::error( 'Реактив не знайдено в лабораторії!' ); }
        if( !$data2db['quantity'] )     { return self::error( 'Не зазначена кількість використаного реактиву!' ); }
        if( !$data2db['inc_expert_id'] ){ return self::error( 'Не вказано хто використовував реактив!' ); }
        if( strtotime($data2db['date']) > time() ){ return self::error( 'Не можна використовувати реактив в майбутньому!', 'inc_date' ); }
        if( strtotime($data2db['date']) < $time_minimal ){ return self::error( 'Не можна використати реактив в таку сиву давнину!', 'inc_date' ); }

        $dispersion = ( new dispersion )->get_raw( array( 'id' => $data2db['dispersion_id'] ) );
        if( !is_array($dispersion) || !isset($dispersion[$data2db['dispersion_id']]) ){ return self::error( 'Реактив не знайдено в лабораторії!' ); }
        $dispersion = $dispersion[$data2db['dispersion_id']];

        $stock = ( new stock )->get_raw( array( 'id' => $dispersion['stock_id'] ) );
        if( !is_array($stock) || !isset($stock[$dispersion['stock_id']]) ){ return self::error( 'Реактив не знайдено на складі!' ); }
        $stock = $stock[$dispersion['stock_id']];

        $reagent    = ( new spr_manager('reagent') )->get_raw( array( 'id' => common::integer( $dispersion['reagent_id'] ) ) )[$dispersion['reagent_id']];

        //if( !$data['utilisation'] && time() > strtotime($stock['dead_date']) ){ return self::error( 'Речовина "'.addslashes( $reagent['name'] ).' ['.$stock['reagent_number'].']" зіпсована!' ); }
        if( !$data['utilisation'] && strtotime($data2db['date']) > strtotime($stock['dead_date']) ){ return self::error( 'Речовина "'.addslashes( $reagent['name'] ).' ['.$stock['reagent_number'].']" зіпсована, її неможливо використати!' ); }

        $old_data = $this->get_raw( array( 'consume_hash' => $hash ) );
        $old_data = ( is_array($old_data) && count($old_data) ) ? reset( $old_data ) : array();
        $old_data['quantity'] = isset($old_data['quantity']) ? common::numeric( $old_data['quantity'] ) : 0;

        if( ( $data2db['quantity'] - $old_data['quantity'] ) > $dispersion['quantity_left'] ){ return self::error( 'Ви намагаєесь використати речовини "'.addslashes( $reagent['name'] ).' ['.$stock['reagent_number'].']" більше, ніж є в лабораторії!' ); }

        if( $stock['group_id'] != $dispersion['group_id'] || $dispersion['group_id'] != CURRENT_GROUP_ID ){ return self::error( 'Ви намагаєтесь використати речовину не з своєї лабораторії! Бан підмережі?' ); }

        $data2db = array_map( array( $this->db, 'safesql' ), $data2db );

        if( !$hash )
        {
            $query = 'INSERT INTO consume '.db::array2ins( $data2db ).' RETURNING hash;';
        }
        else
        {
            $query = 'UPDATE consume SET '.db::array2upd( $data2db ).' WHERE hash = \''.$this->db->safesql( $hash ).'\' RETURNING hash;';
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
                consume.hash    as consume_hash,
                reactiv.hash 	as reactiv_hash,
                "using".hash 	as using_hash,
                consume.quantity,
                consume.inc_expert_id,
                consume.dispersion_id,
                consume.consume_ts,
                consume.date    as consume_date,
                dispersion.inc_date as dispersion_inc_date,
                dispersion.quantity_left as dispersion_quantity_left,
                dispersion.quantity_inc as dispersion_quantity_inc,
                stock.reagent_id,
                stock.dead_date,
                stock.reagent_number
            FROM
                consume
                    LEFT JOIN dispersion       ON( dispersion.id = consume.dispersion_id )
                    LEFT JOIN stock            ON( stock.id = dispersion.stock_id )
                    LEFT  JOIN consume_using    ON( consume_using.consume_hash = consume.hash )
                    LEFT  JOIN "using"          ON( consume_using.using_hash = "using".hash )
                    LEFT  JOIN reactiv_ingr_reagent ON( reactiv_ingr_reagent.consume_hash = consume.hash )
                    LEFT  JOIN reactiv          ON( reactiv.hash = reactiv_ingr_reagent.reactiv_hash )

            '.$WHERE.'
            ORDER BY consume.date DESC;
            ; '.QUERY_CACHABLE;

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

            $row['quantity']                    = common::numeric( $row['quantity'] );
            $row['dispersion_quantity_inc']     = common::numeric( $row['dispersion_quantity_inc'] );
            $row['dispersion_quantity_left']    = common::numeric( $row['dispersion_quantity_left'] );

            $data[$row['consume_hash']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }

}