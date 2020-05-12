<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )          { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) )   { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class access
{
    use basic, spr, db_connect;

    public static final function check( $area, $area_action = false )
    {
        $area = strtolower($area);
        $area_action = strtolower($area_action);

        $area = common::filter( $area );
        $area_action = common::filter( $area_action );

        $ch = $area . ( $area_action ? ':'.$area_action : '' );

        if( !self::allow( $area, $area_action ) )
        {
            $err = 'Поточний користувач не має доступу до модулю "'._MOD_.'" з рівнем доступу "'.$ch.'"! Зверніться до адміністратора!';
            if( _AJAX_ )
            {
                ajax::set_error( rand(10,99), $err );
                return false;
            }
            else
            {
                common::err( $err );
                exit;
                return false;
            }
        }
        return true;
    }

    public static final function allow( $area, $area_action = false )
    {
        $levels = (new access)->get( CURRENT_USER_ID );

        if( !is_array($levels) || !count($levels) ){ return false; }

        $area = strtolower($area);
        $area_action = strtolower($area_action);

        $area = common::filter( $area );
        $area_action = common::filter( $area_action );

        $ch = $area . ( $area_action ? ':'.$area_action : '' );

        if( array_key_exists( $ch, $levels ) && common::integer($levels[$ch]['access_id']) ){ return true; }

        return false;
    }

    public final function get( $user_id = false )
    {
        $user_id = $user_id ? $user_id : CURRENT_USER_ID;
        $SQL = '
                SELECT
                    access.id                   as access_id,
                    access.name                 as access_name,
                    spr_access_actions.id       as action_id,
                    lower(spr_access_actions.label)    as action_label,
                    spr_access_actions.name     as action_name
                FROM
                    access_actions
                    LEFT JOIN access ON( access_actions.access_id = access.id )
                    LEFT JOIN expert ON( access.id = expert.access_id )
                    LEFT JOIN spr_access_actions ON( access_actions.action_id = spr_access_actions.id )
                WHERE
                    access.id > 0
                    AND
                    expert.id = '.$user_id.'
                ORDER by spr_access_actions.label ASC';

        $cache_var = 'access-user-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );
        while( ($row = $this->db->get_row($SQL)) !== false )
        {
            $data[$row['action_label']] = $row;
        }

        return $data;
    }

    public final function save( $action, $action_id, $group_id )
    {
        $action_id = common::integer( $action_id );
        $group_id  = common::integer( $group_id );

        $SQL = array();
        $SQL[] = 'BEGIN;';
        $SQL[] = 'DELETE FROM access_actions WHERE action_id=\''.$action_id.'\' AND access_id=\''.$group_id.'\';';

        if( $action != 'del' )
        {
            $SQL[] = 'DELETE FROM access_actions WHERE action_id=\''.$action_id.'\' AND access_id=\''.$group_id.'\';';
            $SQL[] = 'INSERT INTO access_actions (action_id,access_id) VALUES (\''.$action_id.'\', \''.$group_id.'\');';
        }
        $SQL[] = 'COMMIT;';
        $this->db->query( implode( "\n", $SQL ) );

        cache::clean( 'access' );
    }

    public final function editor()
    {
        $actions        = $this->get_actions_raw();
        $access_actions = $this->get_access_actions_raw();

        $tpl = new tpl;

        foreach( $this->get_groups_raw() as $access_group )
        {
            if( !isset($access_actions[$access_group['id']]) ){ $access_actions[$access_group['id']] = array(); }

            foreach( $actions as $action )
            {
                $tpl->load( 'access/action' );
                $tpl->set( '{group:id}', $access_group['id'] );

                if( in_array( $action['id'], $access_actions[$access_group['id']] ) )
                {
                    $tpl->set( '{action:checked}', 'checked="checked"' );
                }
                else
                {
                    $tpl->set( '{action:checked}', '' );
                }

                foreach( $action as $k => $v )
                {
                    $tpl->set( '{action:'.$k.'}', common::db2html( $v ) );
                }

                $tpl->compile( 'access/action' );
            }

            $tpl->load( 'access/level' );

            foreach( $access_group as $k => $v )
            {
                $tpl->set( '{group:'.$k.'}', common::db2html( $v ) );
            }

            $tpl->set( '{actions}', $tpl->result( 'access/action' ) );
            $tpl->compile( 'access/level' );
        }

        return $tpl->result( 'access/level' );
    }

    public final function get_access_actions_raw()
    {
        $SQL = 'SELECT * FROM access_actions ORDER by access_id ASC';

        $cache_var = 'access-actions-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );
        while( ($row = $this->db->get_row($SQL)) !== false )
        {
            if( !isset($data[$row['access_id']]) ){ $data[$row['access_id']] = array(); }
            $data[$row['access_id']][] = $row['action_id'];
            $data[$row['access_id']] = array_unique( $data[$row['access_id']] );
        }

        return $data;
    }

    public final function get_actions_raw()
    {
        $SQL = 'SELECT * FROM spr_access_actions WHERE id > 0 ORDER by name ASC';

        $cache_var = 'access-actions_spr-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );
        while( ($row = $this->db->get_row($SQL)) !== false )
        {
            $data[$row['id']] = $row;
        }

        return $data;
    }

    public final function get_groups_raw()
    {
        $SQL = 'SELECT * FROM access WHERE id > 0 ORDER by position ASC';

        $cache_var = 'access-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );
        while( ($row = $this->db->get_row($SQL)) !== false )
        {
            $data[$row['id']] = $row;
        }

        return $data;
    }

}