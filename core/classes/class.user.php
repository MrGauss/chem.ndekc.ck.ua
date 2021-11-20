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

    public final function save( $data )
    {
        access::check( 'users', 'edit' );

        if( !$data || !is_array($data) || !count($data) ){ return self::error( 'Помилка передачі даних!' ); }
        if( !isset($data['id']) ){ return self::error( 'Помилка передачі даних!' ); }

        $ID = common::integer( $data['id'] );

        $editable_user = $ID ? $this->get_user_data_raw( $ID )[$ID] : array();

        $ins2db = array();
        $ins2db['surname']  = common::filter( isset($data['surname'])?$data['surname']:'' );
        $ins2db['name']     = common::filter( isset($data['name'])?$data['name']:'' );
        $ins2db['phname']   = common::filter( isset($data['phname'])?$data['phname']:'' );

        if( isset($data['password']) ){ $ins2db['password'] = common::trim( $data['password'] ); }
        if( isset($data['login']) ){ $ins2db['login'] = preg_replace( '!\W+!is', '', common::filter( $data['login'] ) ); }

        if( access::allow( 'users', 'lab' ) )
        {
            if( isset($data['group_id']) ){ $ins2db['group_id'] = common::integer( $data['group_id'] ); }
        }
        else{ $ins2db['group_id'] = CURRENT_GROUP_ID; }

        //$ins2db['group_id'] = CURRENT_GROUP_ID;

        if( access::allow( 'users', 'access' ) )
        {
            if( isset($data['access_id']) ){ $ins2db['access_id'] = common::integer( $data['access_id'] ); }
        }
        else{ $ins2db['access_id'] = isset($editable_user['access_id'])?$editable_user['access_id']:4; }

        //////////////////////////////////////////////////////////////////////////////////

        if( !$ID )
        {
            if( !isset($ins2db['password']) ){ return self::error( 'Зазначте пароль!', 'password' ); }
            if( !isset($ins2db['login']) ){ return self::error( 'Зазначте логін!', 'password' ); }
        }

        if( isset($ins2db['login']) && strlen($ins2db['login']) < 8 )   { return self::error( 'Занадто короткий логін! Мінімум 8 символів!', 'login' ); }
        if( isset($ins2db['login']) && strlen($ins2db['login']) > 32 )  { return self::error( 'Занадто довгий логін! Максимум 32 символи!', 'login' ); }

        if( isset($ins2db['password']) && strlen($ins2db['password']) < 8 )                                         { return self::error( 'Занадто короткий пароль! Мінімум 8 символів!', 'password' ); }
        if( isset($ins2db['password']) && !strlen( preg_replace( '!\d+!is', '', $ins2db['password'] ) ) )           { return self::error( 'Пароль не може складатись лише з цифр!', 'password' ); }
        if( isset($ins2db['password']) && !strlen( preg_replace( '![[:alpha:]]+!is', '', $ins2db['password'] ) ) )   { return self::error( 'Пароль має містити цифри!', 'password' ); }

        if( isset($ins2db['name']) && strlen($ins2db['name']) < 3 )   { return self::error( 'Ім\'я занадто коротке! Вас дісно так звати?', 'name' ); }
        if( isset($ins2db['name']) && strlen($ins2db['name']) > 24 )  { return self::error( 'Ім\'я занадто довге! Вас дісно так звати?', 'name' ); }

        if( isset($ins2db['surname']) && strlen($ins2db['surname']) < 3 )   { return self::error( 'Прізвище занадто коротке! Може варто його змінити?', 'surname' ); }
        if( isset($ins2db['surname']) && strlen($ins2db['surname']) > 24 )  { return self::error( 'Прізвище занадто довге! Може варто його змінити?', 'surname' ); }

        if( isset($ins2db['phname']) && strlen($ins2db['phname']) < 2 )   { return self::error( 'Ім\'я по батькові занадто коротке!', 'phname' ); }
        if( isset($ins2db['phname']) && strlen($ins2db['phname']) > 24 )  { return self::error( 'Ім\'я по батькові занадто довге!', 'phname' ); }

        if( !$ins2db['access_id'] )  { return self::error( 'Не зазначено рівень доступу!', 'access_id' ); }
        if( !$ins2db['group_id'] )   { return self::error( 'Не зазначено лабораторію!', 'group_id' ); }

        //////////////////////////////////////////////////////////////////////////////////

        if( in_array( $ins2db['access_id'], array( 1, 2 ) )  && $this->get_user_data_raw( CURRENT_USER_ID )[CURRENT_USER_ID]['access_id'] != 1 )
        {
            return self::error( 'Вам заборонено створювати адміністраторів!' );
        }

        if( in_array( $ins2db['access_id'], array( 1, 2 ) )  && $this->get_user_data_raw( CURRENT_USER_ID )[CURRENT_USER_ID]['access_id'] == 2 )
        {
            return self::error( 'Вам заборонено створювати адміністраторів!' );
        }

        //////////////////////////////////////////////////////////////////////////////////

        if( isset($ins2db['password']) ){ $ins2db['password'] = self::passencode( $ins2db['password'] ); }
        foreach( $ins2db as $k => $v ){ $ins2db[$k] = $this->db->safesql($v); }

        //////////////////////////////////////////////////////////////////////////////////

        $SQL = '';
        if( $ID > 0 )
        {
            foreach( $ins2db as $k => $v ){ $ins2db[$k] = '"'.$k.'"=\''.$v.'\''; }
            $SQL = 'UPDATE expert SET '.implode( ', ', $ins2db ).' WHERE id='.$ID.' RETURNING id;';
        }
        else
        {
            $SQL = 'INSERT INTO expert ( "'.implode( '", "', array_keys( $ins2db ) ).'" ) VALUES ( \''.implode( '\', \'', array_values($ins2db) ).'\' ) RETURNING id;';
        }

        $ID = $this->db->super_query( $SQL )['id'];

        cache::clean();

        return $ID;
    }

    public final function editor( $user_id = false )
    {
        $data = $this->get_raw( array( 'id' => $user_id, 'group_id' => CURRENT_GROUP_ID ) );

        if( !isset($data[$user_id]) ){ return self::error( 'Помилка передачі даних!' ); }


        $data           = $data[$user_id];
        $access         = ( new access )->get_groups_raw();


        if( access::allow( 'admin', 'change_ndekc' ) && access::allow( 'admin', 'change_lab' ) )
        {
            $labs = $this->get_labs_raw( true );
        }
        else
        {
            $labs = $this->get_labs_raw();
        }



        if( $user_id && $data['access_id'] == 1 &&  $this->get_user_data_raw( CURRENT_USER_ID )[CURRENT_USER_ID]['access_id'] != 1 )
        {
            return self::error( 'Вам заборонено редагувати адміністраторів!' );
        }

        if( $user_id && $data['access_id'] == 2 && !in_array( $this->get_user_data_raw( CURRENT_USER_ID )[CURRENT_USER_ID]['access_id'], array( 1, 2 ) ) )
        {
            return self::error( 'Вам заборонено редагувати адміністраторів!' );
        }

        $tpl = new tpl;
        $tpl->load( 'users/editor' );

        $data['key'] = common::key_gen( 'user-'.$user_id );

        foreach( $data as $k => $v )
        {
            $tpl->set( '{tag:'. $k .'}', common::db2html( $v ) );
        }

        $opts = array();
        foreach( $access as $id => $line )
        {
            $opts[] = '<option value="'.$id.'">'.common::db2html( $line['name'] ).'</option>';
        }
        $tpl->set( '{list:access}', implode( "\n", $opts ) );

        $opts = array();
        foreach( $labs as $id => $line )
        {
            $opts[] = '<option value="'.$id.'">'.common::db2html( $line['region_name'].': '.$line['name'] ).'</option>';
        }
        $tpl->set( '{list:labs}', implode( "\n", $opts ) );


        $tpl->compile( 'users/editor' );
        return $tpl->result( 'users/editor' );
    }

    public final function get_html( $filters = array() )
    {
        access::check( 'users', 'edit' );

        $data = $this->get_raw( $filters );

        $tpl = new tpl;

        $access = ( new access )->get_groups_raw();

        //var_export($data);exit;

        foreach( $data as $user_id => $user_data )
        {
            $user_data['token']     = null;
            $user_data['password']  = null;
            $user_data['key'] = common::key_gen( 'user-'.$user_id );

            $tpl->load( 'users/line' );

            $user_data['ts'] = common::en_date( $user_data['ts'], 'Y.m.d H:i:s' );

            foreach( $user_data as $k => $v )
            {
                if( is_array($v) || is_null($v) ){ continue; }

                $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            }

            foreach( $access[$user_data['access_id']] as $k => $v )
            {
                if( is_array($v) || is_null($v) ){ continue; }

                $tpl->set( '{access:'.$k.'}', common::db2html( $v ) );
            }

            $tpl->compile( 'users/line' );
        }

        return $tpl->result( 'users/line' );
    }


    public final function get_raw( $filters = array() )
    {
        $filters = is_array($filters)?$filters:array();

        $WHERE = array();

        if( isset($filters['visible'] ) )   { $WHERE['expert.visible']      = 'expert.visible   = '.(common::integer( $filters['visible'] )?1:0).''; }
        if( isset($filters['region_id'] ) ) { $WHERE['groups.region_id']    = 'groups.region_id = '.common::integer( $filters['region_id'] ).''; }
        if( isset($filters['group_id'] ) )
        {
            $filters['group_id'] = common::integer( $filters['group_id'] );
            $filters['group_id'] = is_array( $filters['group_id'] ) ? $filters['group_id'] : array( $filters['group_id'] );
            $WHERE['expert.group_id']     = 'expert.group_id IN('.implode(',', $filters['group_id']).')';
        }


        if( isset($filters['id'] ) )
        {
            if( $filters['id'] == 0 ){ $WHERE = array(); }
            $WHERE['expert.id'] = 'expert.id = '.common::integer($filters['id']).'';
        }
        else
        {
            $WHERE['expert.id']         = 'expert.id > 0';
            if( !isset($WHERE['expert.group_id']) || !$WHERE['expert.group_id'] )
            {
                $WHERE['expert.group_id']   = 'expert.group_id  = '.CURRENT_GROUP_ID;
            }
        }

        $SQL = '
            SELECT
                expert.*,
                groups.region_id as region_id
            FROM
                expert
                LEFT JOIN groups ON( groups.id = expert.group_id )
            WHERE
                '.implode( ' AND ', $WHERE ).'
            ORDER BY expert.surname, expert.name, expert.phname;
        ; '.QUERY_CACHABLE;

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

    public final function get_labs_raw( $no_region = false )
    {
        $SQL =
        '
                    SELECT
                        groups.*,
                        region.name as region_name
                    FROM
                        groups
                            LEFT JOIN region ON( region.id = groups.region_id )
                    WHERE
                        groups.id > 0
                        AND
                        ' .( $no_region ? 'groups.region_id > 0' : 'groups.region_id = '.CURRENT_REGION_ID.'' ). '
                    ORDER by
                        groups.name ASC; '.QUERY_CACHABLE;

        $cache_var = 'labs-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );
        while( ($row = $this->db->get_row($SQL)) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }



}

