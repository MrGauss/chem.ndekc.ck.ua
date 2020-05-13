<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )          { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) )   { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class prolongation
{
    use basic, spr, db_connect;

    public final static function error( $error, $error_area = false )
    {
        if( $error != false )
        {
            if( _AJAX_ )
            {
                ajax::set_error( rand(10,99), $error );
                ajax::set_data( 'err_area', isset($error_area) ? $error_area : '' );
                return false;
            }
            else
            {
                common::err( $error );
                return false;
            }
        }
        return true;
    }

    public final function editor( $stock_id = false, $skin = false )
    {
        access::check( 'stock', 'view' );
        
        $skin       = $skin ? $skin : 'prolongation/editor';
        $stock_id   = common::integer( $stock_id );

        if( !$stock_id ){ return false; }

        $stock   = ( new stock )->get_raw( array( 'id' => $stock_id ) )[$stock_id];
        if( !is_array($stock) || !count($stock) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw()[$stock['reagent_id']];
        if( !is_array($reagent) || !count($reagent) ){ return false; }

        $units   = ( new spr_manager( 'units' ) )->get_raw()[$reagent['units_id']];
        if( !is_array($units) || !count($units) ){ return false; }

        //////////////

        $stock['key'] = common::key_gen( $stock['id'] );

        //////////////

        $tpl = new tpl;
        $tpl->load( $skin );

        $tags = array();

        foreach( $stock as $k => $v )
        {
            if( is_array($v) ){ continue; }
            $tpl->set( '{stock:'.$k.'}', common::db2html( $v ) );
            $tags[] = '{stock:'.$k.'}';
        }

        foreach( $reagent as $k => $v )
        {
            if( is_array($v) ){ continue; }
            $tpl->set( '{reagent:'.$k.'}', common::db2html( $v ) );
            $tags[] = '{reagent:'.$k.'}';
        }

        foreach( $units as $k => $v )
        {
            if( is_array($v) ){ continue; }
            $tpl->set( '{units:'.$k.'}', common::db2html( $v ) );
            $tags[] = '{units:'.$k.'}';
        }

        $tpl->set( '{prolongation:list}', $this->get_prolongation_list_html( $stock_id ) );

        $tpl->compile( $skin );
        return $tpl->result( $skin );
    }


    public final function remove( $stock_id, $line_hash )
    {
        access::check( 'stock', 'edit' );

        $stock_id  = common::integer( $stock_id );
        $line_hash = common::filter_hash($line_hash);

        if( !$line_hash ){ return false; }
        if( !$stock_id ) { return false; }

        $stock   = ( new stock )->get_raw( array( 'id' => $stock_id ) )[$stock_id];
        if( !is_array($stock) || !count($stock) ){ self::error( 'Запис не знадений на складі!' ); }

        if( common::integer($stock['group_id']) != CURRENT_GROUP_ID )
        {
            return self::error( 'Доступ заборонено!' );
        }

        $SQL = 'DELETE FROM prolongation WHERE expert_id = '.CURRENT_USER_ID.' AND hash = \''.$line_hash.'\' AND stock_id = \''.$stock_id.'\';';
        $this->db->query( $SQL );

        cache::clean();

        return $line_hash;
    }

    public final function save( $raw_data )
    {
        access::check( 'stock', 'edit' );

        if( !is_array($raw_data) ){ return self::error( 'Помилка передачі даних!' ); }

        $_2db = array();
        $_2db['stock_id']               = common::integer( isset($raw_data['stock_id'])             ? $raw_data['stock_id']             : false );
        $_2db['date_before_prolong']    = common::en_date( isset($raw_data['date_before_prolong'])  ? $raw_data['date_before_prolong']  : false ,'Y-m-d');
        $_2db['date_after_prolong']     = common::en_date( isset($raw_data['date_after_prolong'])   ? $raw_data['date_after_prolong']   : false ,'Y-m-d');
        $_2db['expert_id']              = CURRENT_USER_ID;
        $_2db['act_date']               = common::en_date( isset($raw_data['act_date'])             ? $raw_data['act_date']             : false ,'Y-m-d');
        $_2db['act_number']             = common::filter(  isset($raw_data['act_number']) ? $raw_data['act_number'] : '' );

        $stock   = ( new stock )->get_raw( array( 'id' => $_2db['stock_id'] ) )[$_2db['stock_id']];
        if( !is_array($stock) || !count($stock) ){ self::error( 'Запис не знадений на складі!' ); }

        if( common::integer($stock['group_id']) != CURRENT_GROUP_ID )
        {
            return self::error( 'Доступ заборонено!' );
        }

        if( strtotime( $stock['dead_date'] ) > strtotime( $_2db['date_after_prolong'] ) )
        {
            return self::error( 'Поточна кінцева дата більша за запропоновану!', 'date_after_prolong' );
        }

        if( strtotime( $_2db['date_before_prolong'] ) > strtotime( $_2db['date_after_prolong'] ) )
        {
            return self::error( 'Помилка в датах!', 'date_after_prolong|date_before_prolong' );
        }

        if( strtotime( $_2db['act_date'] ) > time() )
        {
            return self::error( 'Дата акту в майбутньому!', 'act_date' );
        }

        if( strlen( $_2db['act_number'] ) > 30 )
        {
            return self::error( 'Номер акту занадто довгий!', 'act_number' );
        }

        //
        $max_date_after_prolong = $this->db->super_query( 'SELECT date_after_prolong FROM prolongation WHERE stock_id = '.$_2db['stock_id'].' ORDER BY date_after_prolong DESC LIMIT 1;' );
        if( isset($max_date_after_prolong) && isset($max_date_after_prolong['date_after_prolong']) )
        {
            $max_date_after_prolong = strtotime( $max_date_after_prolong['date_after_prolong'] );
            if( $max_date_after_prolong > strtotime( $_2db['date_after_prolong'] ) )
            {
                return self::error( 'Вже існує запис з кінцевою датою більшою за запропоновану ('.date('Y.m.d',$max_date_after_prolong).')!', 'date_after_prolong' );
            }
        }
        //

        $SQL = 'INSERT INTO prolongation ("'.implode('", "', array_keys($_2db) ).'") VALUES ( \''. implode( '\', \'', array_values($_2db) ) .'\' ) RETURNING stock_id, hash;';

               $this->db->query( 'BEGIN;' );
        $SQL = $this->db->query( $SQL );
        $SQL = $this->db->get_row( $SQL );

        if( is_array($SQL) && isset($SQL['hash']) && isset($SQL['stock_id']) && strlen($SQL['hash']) == 32 )
        {
            $this->db->query( 'COMMIT;' );
            $dead_date = $this->db->super_query( 'UPDATE stock SET dead_date = ( SELECT date_after_prolong FROM prolongation WHERE stock_id = stock.id ORDER BY date_after_prolong DESC LIMIT 1 ) WHERE id = '.$SQL['stock_id'].' RETURNING dead_date;' );

            cache::clean();

            return array( 'hash' => $SQL['hash'], 'stock_id' => $SQL['stock_id'], 'dead_date' => $dead_date['dead_date'] );
        }

        $this->db->query( 'ROLLBACK;' );
        return false;
    }



    public final function get_prolongation_list_html( $stock_id )
    {
        $stock_id   = common::integer( $stock_id );
        $data       = $this->get_raw( array( 'stock_id' => array( common::integer( $stock_id ) ) ) );

        if( !is_array($data) || !count($data) ){ return false; }

        $skin = 'prolongation/editor_line';

        $tpl = new tpl;

        foreach( $data as $hash => $line )
        {
            $tpl->load( $skin );

            $line['date_before_prolong'] = common::en_date( $line['date_before_prolong'],'Y.m.d');
            $line['date_after_prolong']  = common::en_date( $line['date_after_prolong'],'Y.m.d');
            $line['act_date']            = common::en_date( $line['act_date'],'Y.m.d');
            $line['date_prolong']        = common::en_date( $line['date_prolong'],'Y.m.d');

            $line['key'] = common::key_gen( $line['stock_id'] . $line['hash'] );

            foreach( $line as $k => $v )
            {
                $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            }

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['expert.group_id'] = 'expert.group_id IN( 0, '.CURRENT_GROUP_ID.' )';

        if( !is_array($filters) ){ $filters = array(); }

        if( isset($filters['stock_id']) && is_array($filters['stock_id']) && count($filters['stock_id']) )
        {
            $WHERE['stock_id'] = 'stock_id IN('. implode( ',', common::integer($filters['stock_id']) ) .')';
        }


        $SQL = 'SELECT
                    prolongation.*,
                    expert.surname  as expert_surname,
                    expert.name     as expert_name,
                    expert.phname   as expert_phname,
                    expert.group_id as expert_group_id
                FROM
                    prolongation
                        LEFT JOIN stock     ON( prolongation.stock_id   = stock.id      )
                        LEFT JOIN expert    ON( prolongation.expert_id  = expert.id     )
                WHERE
                    '.implode( ' AND ', $WHERE ).'
                ORDER BY
                    prolongation.date_prolong DESC;
        ';

        $cache_var = 'stock-prolongation-'.md5( $SQL ).'-raw';
        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }

        $data = array();
        $SQL = $this->db->query( $SQL );
        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['hash']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }
}