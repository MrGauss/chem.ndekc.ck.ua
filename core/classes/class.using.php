<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class using
{
    use basic, spr, db_connect;

    public final function editor( $line_hash = '', $skin = false )
    {
        $line_hash = common::filter_hash( $line_hash );

        $data = $this->get_raw( array( 'hash' => $line_hash ) );
        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : false;

        if( !is_array($data) ){ return false; }

        $_dates = array();
        $_dates[] = 'date';

        foreach( $_dates as $_date )
        {
            $data[$_date]       = isset($data[$_date])      ? common::en_date( $data[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
            if( strpos( $data[$_date], '.197' ) !== false ){ $data[$_date] = ''; }
        }

        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_hash );

        $tags = array();

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tags[] = '{tag:'.$k.'}';

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            $tpl->set( '{autocomplete:'.$k.':key}', autocomplete::key( 'stock', $k ) );
        }

        if( $data['reactiv_hash'] && $data['reactiv_menu_id'] && isset($data['cooked_reactives']) && is_array($data['cooked_reactives']) && count($data['cooked_reactives']) )
        {
            foreach( $data['cooked_reactives'][$data['reactiv_hash']] as $k => $v )
            {
                if( is_array($v) ){ continue; }

                $tpl->set( '{tag:reactiv:'.$k.'}', common::db2html( $v ) );

                $tags[] = '{tag:reactiv:'.$k.'}';
            }

            $tpl->set( '{tag:reactiv:units:short_name}', ( new spr_manager( 'units' ) )->get_raw()[$data['cooked_reactives'][$data['reactiv_hash']]['reactiv_units_id']]['short_name'] );;
        }

        $tpl->set( '{autocomplete:table}', 'stock' );

        $tpl->compile( $skin );

        //var_export($tags);exit;

        return $tpl->result( $skin );
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        $_dates = array();

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tpl->set( '{tag:'.$key.'}', common::db2html( $value ) );
            }

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
        $filters = is_array($filters) ? $filters : array();
        $WHERE = array();

        if( isset($filters['hash']) )
        {
            $filters['hash'] = common::filter_hash( $filters['hash'] );
            $filters['hash'] = is_array($filters['hash']) ? $filters['hash'] : array( $filters['hash'] );

            $filters['hash'] = array_unique($filters['hash']);

            $WHERE['hash']   = '"using".hash IN(\''. implode( '\', \'', array_values( $filters['hash'] ) ) .'\')';
        }
        else
        {
            $WHERE['hash']       = '"using".hash != \'\'';
        }

        $WHERE['group_id']   = '( "using".group_id = '.CURRENT_GROUP_ID.' OR "using".group_id = 0 )';

        /////////////////////

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        /////////////////////

        $SQL = '
            SELECT
                "using".*,
                reactiv.hash as reactiv_hash,
                reactiv.reactiv_menu_id as reactiv_menu_id
            FROM
                "using"
                LEFT JOIN reactiv ON( reactiv.using_hash = "using".hash )
            '.$WHERE.'
            ;';

        $cache_var = 'using-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        $reactives = array();

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['hash']            = common::filter_hash( $row['hash'] );
            $row['reactiv_hash']    = common::filter_hash( $row['reactiv_hash'] );
            $row['reactiv_menu_id'] = common::integer( $row['reactiv_menu_id'] );

            $reactives[$row['hash']] = $row['reactiv_hash'];

            $data[$row['hash']] = $row;
            $data[$row['hash']]['consume']            = array();
            $data[$row['hash']]['reactiv_consume']    = array();
            $data[$row['hash']]['cooked_reactives']   = array();
        }

        foreach( (new consume)->get_raw( array(  'using_hash' => array_keys( $data ) ) ) as $consume )
        {
            if( !isset($data[$consume['using_hash']]) || !is_array($data[$consume['using_hash']]['consume']) )
            {
                common::err( '������� ��������� �����!' );
            }

            $data[$consume['using_hash']]['consume'][$consume['consume_hash']] = $consume;
        }

        foreach( (new reactiv_consume)->get_raw( array(  'using_hash' => array_keys( $data ) ) ) as $consume )
        {
            if( !isset($data[$consume['using_hash']]) || !is_array($data[$consume['using_hash']]['reactiv_consume']) )
            {
                common::err( '������� ��������� �����!' );
            }

            $data[$consume['using_hash']]['reactiv_consume'][$consume['consume_hash']] = $consume;
        }

        foreach( ( new cooked )->get_raw( array(  'using_hash' => array_keys( $data ) ) ) as $ractive )
        {
            if( !isset($data[$ractive['using_hash']]) || !is_array($data[$ractive['using_hash']]['cooked_reactives']) )
            {
                common::err( '������� ��������� �����!' );
            }

            $data[$consume['using_hash']]['cooked_reactives'][$ractive['hash']] = $ractive;
        }

        return $data;
    }









































}