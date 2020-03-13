<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class reagent
{
    use basic, spr, db_connect;

    public static final function get_select( $selected_id = 0 )
    {
        $s = new self();
        $s = $s->get_raw();

        if( !is_array($s) ){ return ''; }

        foreach( $s as $id => $data )
        {
            $data = common::db2html($data);
            $s[$id] = '<option data-units="'.$data['units'].'" value="'.$id.'">'.$data['name'].'</option>';
        }
        return implode( '', $s );
    }

    public static final function get_state_select( $selected_id = 0 )
    {
        $s = new self();
        $s = $s->get_state_raw();

        if( !is_array($s) ){ return ''; }

        foreach( $s as $id => $data )
        {
            $data = common::db2html($data);
            $s[$id] = '<option value="'.$id.'">'.$data['name'].'</option>';
        }
        return implode( '', $s );
    }

    public static final function get_clearence_select( $selected_id = 0 )
    {
        $s = new self();
        $s = $s->get_clearence_raw();

        if( !is_array($s) ){ return ''; }

        foreach( $s as $id => $data )
        {
            $data = common::db2html($data);
            $s[$id] = '<option value="'.$id.'">'.$data['name'].'</option>';
        }
        return implode( '', $s );
    }

    public static final function get_danger_class_select( $selected_id = 0 )
    {
        $s = new self();
        $s = $s->get_danger_class_raw();

        if( !is_array($s) ){ return ''; }

        foreach( $s as $id => $data )
        {
            $data = common::db2html($data);
            $s[$id] = '<option value="'.$id.'">'.$data['name'].'</option>';
        }
        return implode( '', $s );
    }

    //////////////

    public final function get_raw()
    {
        $cache_var = 'spr-reagent-raw';
        $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = 'SELECT * FROM reagent WHERE id > 0 ORDER by name ASC; '.db::CACHED;
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }

    public final function get_state_raw()
    {
        $cache_var = 'spr-reagent_state-raw';
        $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = 'SELECT * FROM reagent_state WHERE id > 0 ORDER by name ASC; '.db::CACHED;
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }

    public final function get_danger_class_raw()
    {
        $cache_var = 'spr-danger_class-raw';
        $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = 'SELECT * FROM danger_class WHERE id > 0 ORDER by name ASC; '.db::CACHED;
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }

    public final function get_clearence_raw()
    {
        $cache_var = 'spr-clearence-raw';
        $data = cache::get( $cache_var );

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = 'SELECT * FROM clearence WHERE id > 0 ORDER by name ASC; '.db::CACHED;
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }

}