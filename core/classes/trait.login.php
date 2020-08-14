<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

trait login
{
	private static $COOKIE_LIFE_TIME = 1;
	private static $PASS_SALT        = 'sd$mo-2l;mpfNKs,svf2eae6rerh$%&43@@!Dl6kv3hkro83v*&(';
	
	private $logged = false;

	public final function is_logged()
	{
		return $this->logged;
	}

	public final function check_auth()
	{
		$login = false;
		$pass  = false;
		$token = false;

		if( isset($_POST['login']) && isset($_POST['pass']) )
		{
		  $login = self::strtolower( self::filter( $_POST['login'] ) );
		  $pass  = self::passencode( $_POST['pass'] );
		}
		elseif( isset($_SESSION['token']) ){ $token  = strip_tags( $_SESSION['token'] ); }
		elseif( isset($_COOKIE['token']) ){  $token  = strip_tags( $_COOKIE['token'] ); }
		else
		{
			define( 'CURRENT_USER_LOGIN', false );
			define( 'CURRENT_USER_ID', false );
			define( 'CURRENT_REGION_ID', false );
			define( 'CURRENT_GROUP_ID', false );
			return false;
		}

		if( ($login && $pass) || $token )
		{
			if( $login && $pass )
			{
				$this->logged = $this->check_login_pass( $login, $pass );
				if( $this->logged ){ $token = $this->update_token(); }
                define( '_TRY_PASS_LOG_IN', true );
			}
			elseif( $token )
			{
				$this->logged = $this->check_token( $token );
                define( '_TRY_SESSION_LOG_IN', true );
			}
			

			if( $this->logged )
			{
				self::set_cookie( 'token', $token );
				$_SESSION['token'] = $token;
				return true;
			}
		}
		else
		{
			define( 'CURRENT_USER_LOGIN', false );
			define( 'CURRENT_USER_ID', false );
			define( 'CURRENT_REGION_ID', false );
			define( 'CURRENT_GROUP_ID', false );
		}
        return false;
	}

    public final function get_curr_user_info()
    {
        return $this->get_users( array( 'user.id' => CURRENT_USER_ID, 'user.region_id' => CURRENT_REGION_ID ) )[CURRENT_USER_ID];
    }

    private final function get_users( $filters = array() )
    {
        $filters['user.id'] = isset($filters['user.id'])?self::integer( $filters['user.id'] ):false;
        $filters['user.region_id'] = isset($filters['user.region_id'])?self::integer( $filters['user.region_id'] ):false;

        $SELECT = array();
        $FROM   = array();
        $WHERE  = array();

        $SELECT['users.id']         = 'user.id';
        $SELECT['users.login']      = 'user.login';
        $SELECT['users.group_id']   = 'user.group_id';
        $SELECT['users.region_id']  = 'user.region_id';

        $FROM['users'] = 'users as users';

        if( $filters['user.id'] !== false )         { $WHERE['user.id'] = 'users.id = '.$filters['user.id'].''; }
        if( $filters['user.region_id'] !== false )  { $WHERE['user.region_id'] = 'users.region_id = '.$filters['user.region_id'].''; }

        foreach( $SELECT as $k=>&$v ){ $v = ''.$k.' as "'.$v.'"'; }
        $SQL = 'SELECT '."\n\t".implode( ','."\n\t", $SELECT )."\n".'FROM '.implode(' ', $FROM ).' '.(count($WHERE)?"\n".'WHERE '.implode( $WHERE, ' AND ' ):'')."\n".'ORDER by users.id;'.QUERY_CACHABLE;

        $var = 'user_data-'.md5($SQL);
        $data = cache::get( $var );
        if( is_array($data) && count($data) ){ return $data; }

        $SQL = $this->db->query( $SQL );
        while( $row = $this->db->get_row($SQL) )
        {
            $data[$row['user.id']] = array();
            foreach( $row as $k=>$v )
            {
                $k = explode('.',$k,2);
                if(!isset($data[$row['user.id']][$k[0]])){ $data[$row['user.id']][$k[0]] = array(); }
                $data[$row['user.id']][$k[0]][$k[1]] = $v;
            }
        }

        cache::set( $var, $data );

        return $data;
    }

	private final function update_token()
	{
		$token = str_shuffle( sha1( mt_rand( 0, 99999 ) ) );
		$token = self::passencode( $token.USER_IP.(isset($_SERVER['HTTP_USER_AGENT'])?$_SERVER['HTTP_USER_AGENT']:md5(date('Y.m.d'))) );

		$SQL = 'UPDATE expert SET token=\''.$token.'\', last_ip=\''.USER_IP.'\', ts=NOW() WHERE id = '.abs(intval(CURRENT_USER_ID)).';';
		$this->db->query( $SQL );

		return $token;
	}

	private final function check_token( $token )
	{
		$token = $this->strtolower( $this->db->safesql( $token ) );
		
		$SQL = '
                SELECT
                    expert.id,
                    expert.login,
                    expert.last_ip,
                    groups.region_id,
                    expert.group_id
                FROM
                    expert
                    LEFT JOIN groups ON( groups.id = expert.group_id )
                WHERE
                    expert.token=\''.$token.'\'
                    AND
                    expert.last_ip=\''.USER_IP.'\'
                LIMIT 1 OFFSET 0;';

		$id = $this->db->super_query( $SQL );

		if( is_array($id) && isset($id['id']) && isset($id['region_id']) )
		{
			define( 'CURRENT_USER_ID',      abs(intval($id['id'])) );
			define( 'CURRENT_USER_LOGIN',   $id['login'] );
			define( 'CURRENT_REGION_ID',    abs(intval($id['region_id'])) );
            define( 'CURRENT_GROUP_ID',     self::integer( $id['group_id'] ) );

			$SQL = 'UPDATE expert SET last_ip=\''.USER_IP.'\', ts=NOW() WHERE id = '.abs(intval(CURRENT_USER_ID)).';';
			$this->db->query( $SQL );
		}
		else
		{
			define( 'CURRENT_USER_ID', false );
			define( 'CURRENT_USER_LOGIN', false );
			define( 'CURRENT_REGION_ID', false );
			define( 'CURRENT_GROUP_ID', false );
		}

		return CURRENT_USER_ID?true:false;
	}
	
	private final function check_login_pass( $login, $pass )
	{
		$login = $this->strtolower( $this->db->safesql( $login ) );
		$pass  = $this->db->safesql( $pass );

        echo '<!-- '.$login.':'.$pass.' -->';

		$SQL = '
                SELECT
                    expert.id,
                    expert.login,
                    expert.last_ip,
                    groups.region_id,
                    expert.group_id
                FROM
                    expert
                    LEFT JOIN groups ON( groups.id = expert.group_id )
                WHERE
                    expert.login=\''.$login.'\'
                    AND
                    expert.password=\''.$pass.'\'
                LIMIT 1
                OFFSET 0;';

        $id = $this->db->super_query( $SQL );

		if( is_array($id) && isset($id['id']) )
		{
			define( 'CURRENT_USER_ID', abs(intval($id['id'])) );
            define( 'CURRENT_USER_LOGIN', $id['login'] );
			define( 'CURRENT_REGION_ID', abs(intval($id['region_id'])) );
			define( 'CURRENT_GROUP_ID', self::integer( $id['group_id'] ) );
		}
		else
		{
			define( 'CURRENT_USER_ID', false );
			define( 'CURRENT_USER_LOGIN', false );
			define( 'CURRENT_REGION_ID', false );
            define( 'CURRENT_GROUP_ID', false );
		}
		
		return CURRENT_USER_ID?true:false;
	}	
	
	private final static function passencode( $str )
	{
		$i = 4;
		while( $i > 0 )
		{
			$i--;
			$str = md5( base64_encode( sha1( self::$PASS_SALT ) . sha1( $str ) ) . $str . strrev( $str ) );
		}
		return $str;
	}
	
	public final static function set_cookie( $name, $value )
	{
        $params = session_get_cookie_params();
        $params['expires'] = time() + $params['lifetime'];
        $params['SameSite'] = 'Strict';
        unset( $params['lifetime'] );

		setcookie( $name, $value, $params );
	}

	public static final function start_session( $sid = false )
	{
	    $params = array
        (
            'lifetime' => 60*60*self::$COOKIE_LIFE_TIME,
            'path' => '/',
            'domain' => DOMAIN,
            'secure' => true,
            'httponly' => true,
            'samesite' => 'strict',
        );
        session_set_cookie_params( $params );

		if ( $sid ){ session_id( $sid );  }
		session_start
        (
            array
            (
                'name' => 'SID',
                'cookie_domain' => DOMAIN,
                'cookie_secure' => true,
                'cookie_httponly' => true,
                'cookie_samesite' => 'strict',
            )
        );
	}

    public final function logout()
    {
        self::set_cookie( 'token', false );
        session_destroy();
        header( 'Location: '.HOME );
        exit;
    }
	
}

