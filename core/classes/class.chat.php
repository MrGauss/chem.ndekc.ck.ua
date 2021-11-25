<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class chat
{
    use basic, db_connect;

    public final function save( $message, $to_expert_id = 0 )
    {
        if( !access::allow( 'chat', 'write' ) )
        {
            return self::error( 'У Вас немає прав писати повідомлення!' );
            exit;
        }

        $message        = ( $message && strlen($message) > 1 ) ? common::trim( common::filter( strip_tags( $message ) ) ) : false;
        $to_expert_id   = common::integer( $to_expert_id );

        if( !$message ){ return self::error( 'Помилка збереження! Повідомлення закоротке!' ); }

        $message = $this->db->safesql( $message );

        $SQL = 'INSERT INTO "chat" ( "from_expert_id", "to_expert_id", "message" ) VALUES ( \''.CURRENT_USER_ID.'\'::INTEGER, \''.$to_expert_id.'\'::INTEGER, \''.$message.'\'::TEXT ) RETURNING hash;';

        $SQL = $this->db->super_query( $SQL );
        $this->db->super_query( 'UPDATE expert SET unread_messages = unread_messages + 1 WHERE id > 0 AND id != '.CURRENT_USER_ID.';' );

        cache::clean( 'chat' );

        return true;
    }

    public final function parse_user( $data )
    {
        $login = ( is_array($data) && isset( $data[1] ) ) ? common::filter( $data[1] ) : false;
        if( !$login ){ return ( isset($data[0]) ? $data[0] : false ); }

        $cache_var = 'chat_logins';

        $_LOGINS = array();
        $_LOGINS = cache::get( $cache_var );

        if( !$_LOGINS || !is_array($_LOGINS) || !count($_LOGINS) )
        {
            $_LOGINS = array();
            $SQL = 'SELECT id, login, name, surname, phname, access_id FROM expert ORDER BY surname, name, phname;';
            $SQL = $this->db->query( $SQL );
            while( ( $row = $this->db->get_row($SQL) ) != false )
            {
                $row = common::stripslashes( $row );
                $_LOGINS[$row['login']] = $row;
            }
            cache::set( $cache_var, $_LOGINS );
        }

        if( !isset($_LOGINS[$login]) ){ return ( isset($data[0]) ? $data[0] : false ); }

        return '<a title="'.common::db2html( $_LOGINS[$login]['surname'].' '.$_LOGINS[$login]['name'].' '.$_LOGINS[$login]['phname'] ).'" data-login="'.$login.'" data-access_id="'.$_LOGINS[$login]['access_id'].'">'.$_LOGINS[$login]['surname'].' '.substr( $_LOGINS[$login]['name'], 0, 1 ).'.'.substr( $_LOGINS[$login]['phname'], 0, 1 ).'.</a>';
    }

    public static function parse_bb( $text )
    {
        $text = preg_replace( '!\[(b|i|u)\](.+?)\[\/\1\]!is', '<$1>$2</$1>', $text );
        $text = preg_replace( '!\[(red|green|blue|yellow|pink|black)\](.+?)\[\/\1\]!is', '<span data-color="$1">$2</span>', $text );
        $text = preg_replace( '!\[(left|center|right|justify)\](.+?)\[\/\1\]!is', '<div class="align_$1">$2</div>', $text );
        $text = preg_replace( '!\[(a)\](.+?)\[\/\1\]!i', '<a href="$2" target="_blank">$2</a>', $text );
        $text = preg_replace( '!\[(a)=(\S+?)\](.+?)\[\/\1\]!i', '<a href="$2" target="_blank">$3</a>', $text );
        return $text;
    }

    public final function get_html( $to_expert_id = 0 )
    {
        $data = $this->get( $to_expert_id );

        if( is_array($data) && count($data) )
        {
            $tpl = new tpl;

            foreach( $data as $message )
            {
                $message['message'] = self::parse_bb( $message['message'] );

                if( !access::allow( 'chat', 'bbcodes' ) ){ $message['message'] = strip_tags( $message['message'] ); }

                $message['message'] = preg_replace_callback( '!\[@(\w+)\]!i', array( $this, 'parse_user' ), $message['message'] );

                $tpl->load( 'chat/line' );

                $message['ts'] = common::en_date( $message['ts'], 'Y.m.d H:i:s' );
                foreach( $message as $k => $v )
                {
                    $v = common::stripslashes( $v );
                    $v = common::html_entity_decode( $v );

                    $tpl->set( '{tag:'.$k.'}', common::trim( $v ) );
                    $tpl->set( '{tag:'.$k.':html}', common::db2html( $v ) );
                }

                $tpl->set( '{tag:name:1}',      common::db2html( substr( $message['name'],    0, 1 ) ) );
                $tpl->set( '{tag:surname:1}',   common::db2html( substr( $message['surname'], 0, 1 ) ) );
                $tpl->set( '{tag:phname:1}',    common::db2html( substr( $message['phname'],  0, 1 ) ) );

                $tpl->compile( 'chat/line' );
            }

            $this->db->super_query( 'UPDATE expert SET unread_messages = 0 WHERE id = '.CURRENT_USER_ID.';' );

            return $tpl->result( 'chat/line' );
        }
        else
        {
            return false;
        }

    }

    public final function get( $to_expert_id = 0 )
    {
        $to_expert_id   = common::integer( $to_expert_id );

        $cache_var = 'chat';

        if( $to_expert_id )
        {
            $cache_var = $cache_var.'_'.CURRENT_USER_ID.'_'.$to_expert_id;
        }

        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }

        $SQL = '
            SELECT
                chat.hash,
                chat.ts,
                chat.from_expert_id,
                chat.to_expert_id,
                chat.message,
                from_expert.login,
                from_expert.access_id,
                from_expert.surname,
                from_expert.name,
                from_expert.phname,
                from_expert.group_id,
                groups.id as group_id,
                groups.name as group_name,
                region.id as region_id,
                region.name as region_name
            FROM chat
                LEFT JOIN expert as from_expert ON( from_expert.id = chat.from_expert_id )
                LEFT JOIN expert as to_expert   ON( to_expert.id = chat.to_expert_id )
                LEFT JOIN groups ON( from_expert.group_id = groups.id )
                LEFT JOIN region ON( groups.region_id = region.id )
           ORDER BY chat.ts DESC
           OFFSET 0
           LIMIT 300;';

        $SQL = $this->db->query( $SQL );
        $data = array();

        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $data[$row['hash']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }


}