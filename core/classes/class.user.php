<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'login' ) )      { require( CLASSES_DIR.DS.'trait.login.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class user
{
	use basic,
		login,
        spr,
		db_connect;

    private $tmp = array();

	public final function __construct()
	{
		$this->__cconnect_2_db();
	}

    public static final function get_current_user_data_raw()
    {
        if( !CURRENT_USER_ID ){ return array(); }

        $t = new user;
        $t = $t->get_user_data_raw( CURRENT_USER_ID )[CURRENT_USER_ID];
        $t = common::db2html($t);

        return $t;
    }

    static public final function get_select( $selected_id = 0 )
    {
        $class = new self;

        $data = $class->get_raw( array( 'visible' => 1 ) );
        $data = is_array($data) ? $data : array();

        foreach( $data as $k=>$line )
        {
            $line = common::db2html( $line );

            $data[$k] = array();
            foreach( $line as $key => $val )
            {
                if( $key == 'token' )    { continue; }
                if( $key == 'last_ip' )  { continue; }
                if( $key == 'group_id' ) { continue; }
                if( $key == 'password' ) { continue; }
                if( $key == 'visible' )  { continue; }

                $data[$k][] = 'data-'.$key.'="'.$val.'"';
            }
            $data[$k] = '<option title="'.$line['surname'].' '.$line['name'].' '.$line['phname'].'" value="'.$line['id'].'" '.implode( ' ', $data[$k] ).'>'.$line['surname'].' '.$line['name'].' '.$line['phname'].'</option>';
        }
        $data = "\n\t".implode( "\n\t", $data )."\n";

        return $data;
    }

    public final function get_raw( $filters = array() )
    {
        $filters = is_array($filters)?$filters:array();

        $WHERE = array();

        if( isset($filters['visible'] ) )   { $WHERE['expert.visible']      = 'expert.visible   = '.(common::integer( $filters['visible'] )?1:0).''; }
        if( isset($filters['region_id'] ) ) { $WHERE['expert.region_id']    = 'expert.region_id = '.common::integer( $filters['region_id'] ).''; }
        if( isset($filters['group_id'] ) )  { $WHERE['expert.group_id']     = 'expert.group_id  = '.common::integer( $filters['group_id'] ).''; }


        if( isset($filters['id'] ) )
        {
            if( $filters['id'] == 0 ){ $WHERE = array(); }
            $WHERE['expert.id'] = 'expert.id = '.common::integer($filters['id']).'';
        }
        else
        {
            $WHERE['expert.id']         = 'expert.id > 0';
            $WHERE['expert.region_id']  = 'expert.id = '.CURRENT_REGION_ID;
            $WHERE['expert.group_id']   = 'expert.id = '.CURRENT_GROUP_ID;
        }

        $SQL = '
            SELECT
                *
            FROM
                expert
            WHERE
                '.implode( ' AND ', $WHERE ).'
            ORDER BY expert.surname, expert.name, expert.phname;
        ';

        $cache_var = 'users-'.md5($SQL);
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['password'] = false;
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }

    public final function get_user_data_raw( $user_id )
    {
        $user_id = common::integer( $user_id );

        return $this->get_raw( array( 'id' => $user_id ) );
    }



}

