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
        $message        = ( $message && strlen($message) > 1 ) ? common::trim( common::filter( strip_tags( $message ) ) ) : false;
        $to_expert_id   = common::integer( $to_expert_id );

        if( !$message ){ return self::error( 'Помилка збереження! Повідомлення закоротке!' ); }

        $message = $this->db->safesql( $message );

        $SQL = 'INSERT INTO "chat" ( "from_expert_id", "to_expert_id", "message" ) VALUES ( \''.CURRENT_USER_ID.'\'::INTEGER, \''.$to_expert_id.'\'::INTEGER, \''.$message.'\'::TEXT ) RETURNING hash;';

        $SQL = $this->db->super_query( $SQL );

        cache::clean( 'chat' );

        return true;
    }

    public final function get_html( $to_expert_id = 0 )
    {
        $data = $this->get( $to_expert_id );

        // var_export($data); exit;

        if( is_array($data) && count($data) )
        {
            $tpl = new tpl;

            foreach( $data as $message )
            {
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
        // $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }

        $SQL = '
            SELECT
                chat.hash,
                chat.ts,
                chat.from_expert_id,
                chat.to_expert_id,
                chat.message,
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
           WHERE chat.ts > ( NOW() - INTERVAL \'7 DAYS\' )
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