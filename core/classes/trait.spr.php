<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

trait spr
{
    public final function get_region_raw()
    {
        $cache_var = 'spr-region-list';
        $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = 'SELECT * FROM region WHERE id > 0 ORDER by id; '.db::CACHED;
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }

    public final function get_groups_raw()
    {
        $cache_var = 'spr-groups-list';
        $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = 'SELECT * FROM groups WHERE id > 0 ORDER by name; '.db::CACHED;
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }


}

