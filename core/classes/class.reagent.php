<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

echo 'FILE: '.__FILE__.' MAY BE DELETED!'; exit;

/*if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }
if( !class_exists( 'spr_manager' ) ){ require( CLASSES_DIR.DS.'class.spr_manager.php' ); }

class reagent
{
    use basic, spr, db_connect;

    const DB_MAIN_TABLE = 'reagent';

    public static final function get_select( $selected_id = 0 )
    {
        $spr = new spr_manager( 'reagent' );
        return  $spr->get_select();
    }

    public static final function get_state_select( $selected_id = 0 )
    {
        $spr = new spr_manager( 'reagent_state' );
        return  $spr->get_select();
    }

    public static final function get_clearence_select( $selected_id = 0 )
    {
        $spr = new spr_manager( 'clearence' );
        return  $spr->get_select();
    }

    public static final function get_danger_class_select( $selected_id = 0 )
    {
        $spr = new spr_manager( 'danger_class' );
        return  $spr->get_select();
    }

    //////////////

    public final function remove( $ID = 0 )
    {
        $ID = common::integer( $ID );
        $error = '';

        if( !$error && !$ID ){ $error = 'Ідентифікатор не визначено!'; }

        ////////////////////////////////////

        $data = array();
        if( !$error && $ID ){ $data = $ID?$this->get_raw(array('id'=>$ID))[$ID] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) )                                  { $error = 'Помилка отримання даних!'; }

        ////////////////////////////////////

        if( $error != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), $error ); return false; }
            else        { common::err( $error ); return false; }
        }

        $SQL = 'DELETE FROM '.self::DB_MAIN_TABLE.' WHERE id='.$ID.' AND region_id='.CURRENT_REGION_ID.' AND group_id='.CURRENT_GROUP_ID.';';
        $this->db->query( $SQL );

        cache::clean();

        return $ID;
    }

    static public final function check_data_before_save( $data4save = array(), $original_data = array() )
    {
        if( !is_array($data4save) ){ return false; }
        if( !is_array($original_data) ){ return false; }

        $ID = common::integer( isset($original_data['id']) ? $original_data['id'] : false );

        $error = false;
        $error_area = false;

        ///////////

        $data4save['units'] = common::strtolower( $data4save['units'] );

        if( common::strlen( $data4save['name'] ) > 64 ) { $error = 'Назва занадто довга!'; $error_area = 'name'; }
        if( common::strlen( $data4save['name'] ) < 3 )  { $error = 'Назва занадто коротка!'; $error_area = 'name'; }
        if( common::strlen( $data4save['units'] ) < 2 ) { $error = 'Одтиниця виміру занадто коротка!'; $error_area = 'units'; }
        if( common::strlen( $data4save['units'] ) > 32) { $error = 'Одтиниця виміру занадто довга!'; $error_area = 'units'; }

        $prefs = array( 'ато', 'фемто', 'піко', 'нано', 'мікро', 'мілі', 'санти', 'деци', 'дека', 'гекто', 'кіло', 'мега', 'гіга', 'тера', 'пета', );
        foreach( $prefs as $pref )
        {
            $pref = strpos( $data4save['units'], $pref );
            if( $pref !== false && $pref === 0 ){ $error = 'Одиниці виміру мають бути без префіксів!'; $error_area = 'units'; }
        }

        ///////////

        if( $error != false )
        {
            if( _AJAX_ )
            {
                ajax::set_error( rand(10,99), $error );
                ajax::set_data( 'err_area', $error_area );
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

    public final function save( $ID = 0, $data = array() )
    {
        $ID = common::integer( $ID );

        if( !is_array($data) ){ return false; }

        $SQL = array();

        $SQL['name']                 = common::filter($data['name']);
        $SQL['units']                = common::filter($data['units']);
        $SQL['created_by_expert_id'] = CURRENT_USER_ID;

        foreach( $SQL as $k => $v )
        {
            $SQL[$k] = $this->db->safesql( $v );
        }

        ///////////////////////////////////////////////////

        if( !self::check_data_before_save( $SQL, $ID?$this->get_raw(array('id'=>$ID))[$ID] : array() ) ){ return false; }

        ///////////////////////////////////////////////////

        if( $ID > 0 )
        {
            foreach( $SQL as $k => $v ){ $SQL[$k] =  '"'.$k.'"= \''.$v.'\''; }
            $SQL = 'UPDATE '.self::DB_MAIN_TABLE.' SET '.implode( ', ', $SQL ).' WHERE id = '.$ID.' RETURNING id;';
        }
        else
        {
            $SQL = 'INSERT INTO '.self::DB_MAIN_TABLE.' ("'.implode('", "', array_keys($SQL) ).'") VALUES ( \''.implode('\', \'', array_values($SQL)).'\' ) RETURNING id;';
        }

        $this->db->query( 'BEGIN;' );
        $ID = $this->db->super_query( $SQL );

        $ID = isset($ID['id']) ? $ID['id'] : false;

        if( $ID ){ $this->db->query( 'COMMIT;' ); }
             else{ $this->db->query( 'ROLLBACK;' ); }

        cache::clean();

        return $ID;
    }

    //////////////
    public final function editor( $line_id = 0, $skin = false )
    {
        $line_id = common::integer( $line_id );

        $data = $this->get_raw( array( 'id' => $line_id ) );
        $data = isset( $data[$line_id] ) ? $data[$line_id] : false;

        if( !is_array($data) ){ return false; }

        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_id );

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
        $spr = new spr_manager( 'reagent' );
        return $spr->get_html( $filters );
    }
    //////////////

    public final function get_raw( $filters = array() )
    {
        $spr = new spr_manager( 'reagent' );
        return $spr->get_raw( $filters );
    }

}       */