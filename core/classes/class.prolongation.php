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

    public final function editor( $stock_id = false, $skin = false )
    {
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


    public final function save( $raw_data )
    {
        $_2db = array();
        $_2db['stock_id']               = common::integer( isset($raw_data['stock_id'])             ? $raw_data['stock_id']             : false );
        $_2db['date_before_prolong']    = common::en_date( isset($raw_data['date_before_prolong'])  ? $raw_data['date_before_prolong']  : false ,'Y-m-d');
        $_2db['date_after_prolong']     = common::en_date( isset($raw_data['date_after_prolong'])   ? $raw_data['date_after_prolong']   : false ,'Y-m-d');
        $_2db['expert_id']              = CURRENT_USER_ID;
        $_2db['act_date']               = common::en_date( isset($raw_data['act_date'])             ? $raw_data['act_date']             : false ,'Y-m-d');
        $_2db['act_number']             = common::filter(  isset($raw_data['act_number']) ? $raw_data['act_number'] : '' );

        $SQL = 'INSERT INTO prolongation ("'.implode('", "', array_keys($_2db) ).'") VALUES ( \''. implode( '\', \'', array_values($_2db) ) .'\' ) RETURNING hash;';

               $this->db->query( 'BEGIN;' );
        $SQL = $this->db->query( $SQL );
        $SQL = $this->db->get_row( $SQL );

        if( is_array($SQL) && isset($SQL['hash']) && strlen($SQL['hash']) == 32 )
        {
            $this->db->query( 'COMMIT;' );

            cache::clean();

            return $SQL['hash'];
        }

        $this->db->query( 'ROLLBACK;' );

        return false;
    }



    public final function get_prolongation_list_html( $stock_id )
    {
        $stock_id   = common::integer( $stock_id );
        $data       = $this->get_raw( array( 'stock_id' => common::integer( $stock_id ) ) );

        if( !is_array($data) || !count($data) ){ return false; }
        $tpl = new tpl;



        return 'fuck!';
    }

    public final function get_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['expert.group_id'] = 'expert.group_id IN( 0, '.CURRENT_GROUP_ID.' )';

        if( !is_array($filters) ){ $filters = array(); }

        if( isset($filters['stock_id']) && is_array($filters['stock_id']) && count($filters['stock_id']) )
        {
            $WHERE['stock_id'] = 'stock_id IN('. implode( ',', common::integer($WHERE['stock_id']) ) .')';
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