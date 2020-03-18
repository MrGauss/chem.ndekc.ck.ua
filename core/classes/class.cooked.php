<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class cooked
{
    use basic, spr, db_connect;

    public final function editor( $line_hash = false, $skin = false )
    {
        $line_hash = common::filter_hash( $line_hash );

        $data = $this->get_raw( array( 'hash' => $line_hash ) );
        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : false;

        if( !is_array($data) ){ return false; }


        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_hash );


        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
        }

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );


            $line['numi'] = $I--;

            $line = common::db2html( $line );

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tpl->set( '{tag:'.$key.'}', $value );
            }

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
        if( is_array($filters) )
        {
            if( isset($filters['hash']) ){ $filters['hash'] = common::filter_hash( $filters['hash'] ); }
        }

        $SQL = '
            SELECT
                reactiv.*,
                reactiv_menu.name       as reactiv_name,
                reactiv_menu.units_id   as reactiv_units_id,
                reactiv_menu."comment"  as reactiv_comment
            FROM
                reactiv
                    LEFT JOIN reactiv_menu ON ( reactiv_menu.id = reactiv.reactiv_menu_id )
            WHERE
                '.(( isset($filters['hash']) ) ? 'reactiv.hash = \''.$filters['hash'].'\'' : 'reactiv.hash != \'\'').'
                '.(( isset($filters['hash']) && $filters['hash'] == '' ) ? ''    :'AND reactiv.region_id = '.CURRENT_REGION_ID.'').'
                '.(( isset($filters['hash']) && $filters['hash'] == '' ) ? ''    :(CURRENT_GROUP_ID?'AND reactiv.group_id = '.CURRENT_GROUP_ID.'':'')).'
            ORDER by
                reactiv_name ASC; '.db::CACHED;

        $cache_var = 'spr-reactiv-'.md5( $SQL ).'-raw';

        $data = false;

        // $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['hash']] = $row;
            $data[$row['hash']]['composition'] = array();
        }

        //////////////////////////////////////////////////////////////////////////////////
        if( is_array($data) && count($data) )
        {
            $SQL = 'SELECT
                        composition.reactiv_hash,
                        composition.consume_hash,

                        consume.dispersion_id,
                        consume.inc_expert_id,
                        consume.consume_ts,
                        consume.quantity,
                        consume.using_hash,

                        "using".purpose_id,
                        purpose.name as purpose_name,
                        purpose.attr as purpose_attr

                    FROM
                        composition
                        LEFT JOIN consume   ON( consume.hash = composition.consume_hash )
                        LEFT JOIN "using"   ON( consume.using_hash = "using".hash )
                        LEFT JOIN purpose   ON( purpose.id = "using".purpose_id )
                    WHERE
                        composition.reactiv_hash IN( \''.implode( '\', \'', array_keys( $data ) ).'\' );';

            $SQL = $this->db->query( $SQL );

            while( ( $row = $this->db->get_row($SQL) ) !== false )
            {
                $data[$row['consume_hash']] = $row;
            }
        }
        //////////////////////////////////////////////////////////////////////////////////

        cache::set( $cache_var, $data );
        return $data;
    }

}