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
        $data['utilisation'] = ( isset( $data['utilisation'] ) && $data['utilisation'] ) ? true : false;
        $hash = isset($data['hash']) ? common::filter_hash( $data['hash'] ) : false;

        if( !$data2db['reactiv_hash'] )                     { return self::error( 'Розчин не знайдено в лабораторії!' );                            }
        if( !$data2db['quantity'] )                         { return self::error( 'Не зазначена кількість використаного розчину!' );                }
        if( !$data2db['inc_expert_id'] )                    { return self::error( 'Не вказано хто використовував розчин!' );                        }
        if( strtotime($data2db['date']) > time() )          { return self::error( 'Не можна використовувати розчин в майбутньому!', 'inc_date' );   }
        if( strtotime($data2db['date']) < $time_minimal )   { return self::error( 'Не можна використати розчин в таку сиву давнину!', 'inc_date' ); }

        $cooked = ( new cooked ) -> get_raw( array( 'hash' => $data2db['reactiv_hash'] ) );
        if( !isset($cooked[$data2db['reactiv_hash']]) )
        {
            return self::error( 'Розчин не знайдено в лабораторії!' );
        }
        $cooked = $cooked[$data2db['reactiv_hash']];

        $recipe = ( new recipes()                )->get_raw();
        if( !isset($recipe[$cooked['reactiv_menu_id']]) )
        {
            return self::error( 'Якась біда з рецептом! Я не можу знайти рецепт, по якому Ви це колотили!' );
        }
        $recipe = $recipe[$cooked['reactiv_menu_id']];


        $old_data = $this->get_raw( array( 'consume_hash' => $hash ) );
        if( isset($old_data[$hash]) ){ $old_data = $old_data[$hash]; }

        $old_data['quantity'] = common::float( isset($old_data['quantity']) ? $old_data['quantity'] : 0 );

        //if( !$data['utilisation'] && strtotime(date('Y-m-d 00:00:01')) > strtotime($cooked['dead_date']) ){ return self::error( time().' - '.strtotime($cooked['dead_date']).'Розчин "'.addslashes($recipe['name']).'" зіпсований, його неможливо використати!' ); }
        if( !$data['utilisation'] && strtotime($data2db['date']) > strtotime($cooked['dead_date']) ){ return self::error( 'Розчин "'.addslashes($recipe['name']).'" зіпсований, його неможливо використати!' ); }
        if( ( $data2db['quantity'] - $old_data['quantity'] ) > $cooked['quantity_left'] ){ return self::error( 'Ви намагаєтесь використати розчину ("'.addslashes($recipe['name']).'") більше, ніж є в лабораторії!' ); }

        if( $cooked['group_id'] != CURRENT_GROUP_ID ){ return self::error( 'Ви намагаєтесь використати речовину не з своєї лабораторії! Бан підмережі?' ); }

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

                reactiv.reactiv_menu_id     as reactiv_menu_id,
                reactiv.inc_date            as reactiv_inc_date,
                reactiv.dead_date           as reactiv_dead_date,
                reactiv.quantity_inc        as reactiv_quantity_inc,
                reactiv.quantity_left       as reactiv_quantity_left
            FROM
                reactiv_consume
                    LEFT JOIN reactiv_consume_using ON( reactiv_consume_using.consume_hash = reactiv_consume.hash )
                        LEFT JOIN "using" ON( "using".hash = reactiv_consume_using.using_hash )
                    LEFT JOIN reactiv_ingr_reactiv ON( reactiv_ingr_reactiv.consume_hash = reactiv_consume.hash )
                        LEFT JOIN reactiv ON( reactiv.hash = reactiv_ingr_reactiv.reactiv_hash )
                '.$WHERE.'
            ORDER BY reactiv_consume.date DESC
            ;';


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