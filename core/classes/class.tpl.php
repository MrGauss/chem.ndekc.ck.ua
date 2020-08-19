<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

class tpl
{
    use basic;

    private $tpl_dir  = false;
    private $cache = array();
    private $theme = array();
    private $buffer = array();
    private $current = false;

    public  $head_tags = array
            (
                'title' => '',
                'description' => '',
                'keywords' => '',
                'charset' => '',
            );

    public final function __construct( $skin_dir = false )
    {
        if( !$skin_dir || !is_dir($skin_dir) ){ $skin_dir = TPL_DIR; }

        $this->tpl_dir = $skin_dir;
    }

    public final function info( $title=false, $message, $level='notice' )
    {
        $this->load( 'info' );
        $this->set( '{info:title}',     self::htmlspecialchars( $title ) );
        $this->set( '{info:message}',   self::htmlspecialchars( $message ) );
        $this->set( '{info:level}',     self::htmlspecialchars( $level ) );
        $this->compile( 'info' );
    }

    public final function load( $skin  = false, $enable_current = true )
    {
        if( !$skin ){ return false; }

        $skin = explode( '/', $skin );
        foreach( $skin as $k=>$v ){ $skin[$k] = self::totranslit($v); }
        $skin = implode( DS, $skin );
        $filename = $this->tpl_dir.DS.$skin.'.tpl';

        if( !file_exists( $filename ) )
        {
            self::err( 'TEMPLATE NOT FOUND: '.$skin.'.tpl' );
            exit;
        }

        if( !isset($this->cache[$skin]) )
        {
            $this->cache[$skin] = self::read_file( $filename );
        }

        $this->theme[$skin] = $this->parse_global_tags( $this->cache[$skin] );

        if( $enable_current ){ $this->current = $skin; }

        return $this->theme[$skin];
    }

    public function set( $tag, $value, $skin=false )
    {
        $skin = $skin?$skin:$this->current;
        if( isset($this->theme[$skin]) )
        {
            if( is_array($value) )
            {
                self::err( 'tag '.$tag.' have array value! String is needed! File: '.__FILE__ );
                exit;
            }
            else
            {
                $this->theme[$skin] = str_replace( $tag, $value, $this->theme[$skin] );
            }
        }
    }

    public final function set_block( $mask, $value, $skin=false )
    {
        $skin = $skin?$skin:$this->current;

        if( isset($this->theme[$skin]) )
        {
            if( is_array($value) )
            {
                self::err( 'mask '.$mask.' have array value! String is needed! File: '.__FILE__ );
                exit;
            }
            $this->theme[$skin] = preg_replace( $mask, $value, $this->theme[$skin] );
        }
    }

    public final function compile( $skin=false )
    {
        if( !$skin ){ $skin = $this->current; }

        if( !isset($this->buffer[$skin]) ){ $this->buffer[$skin] = ''; }

        $this->buffer[$skin] = $this->buffer[$skin].$this->theme[$skin];
        $this->theme[$skin] = '';
    }

    public final function result( $skin=false )
    {
        if( !$skin ){ $skin = $this->current; }
        if( !isset($this->buffer[$skin]) ){ $this->buffer[$skin] = ''; }

        $data = $this->buffer[$skin];
        $this->clean($skin);

        if( $skin == 'content' )
        {
            foreach( $this->head_tags as $key => $value )
            {
                $data = str_replace( '{'.self::strtolower($key).'}', $value, $data );
            }

            foreach( $this->buffer as $key => $value )
            {
                $data = str_replace( '{global:'.$key.'}', $value, $data );
                $this->clean( $key );
            }

            $data = preg_replace( '!\{global:(\w+?)\}!', '', $data );
        }

        while( strpos( $data, '{RAND}' ) !== false )
        {
            $data = preg_replace ( '!\{RAND\}!i', str_shuffle(md5(rand( 1000000, 9999999 ))), $data, 1 );
        }

        while( strpos( $data, '{RAND_NUMBER}' ) !== false )
        {
            $data = preg_replace ( '!\{RAND_NUMBER\}!i', mt_rand( 0, 10000 ), $data, 1 );
        }

        return $data;
    }

    public final function ins( $skin=false, $data )
    {
        if( !$skin ){ $skin = $this->current; }
        if( !isset($this->buffer[$skin]) ){ $this->buffer[$skin] = ''; }

        $this->buffer[$skin] = $this->buffer[$skin].$data;
    }

    public final function clean( $skin=false )
    {
        $skin = $skin?$skin:$this->current;
        $this->theme[$skin] = false;
        $this->cache[$skin] = false;
        $this->buffer[$skin] = false;
        unset( $this->cache[$skin] );
        unset( $this->theme[$skin] );
        unset( $this->buffer[$skin] );
    }

    private final static function str_replace_if_exist( $from, $to, $data )
    {
        if( strpos( $data, $from ) !== false )
        {
            $data = str_replace( $from, $to, $data );
        }
        return $data;
    }

    private final function parse_global_tags( $data )
    {
        $data = self::str_replace_if_exist( '{MOD}', _MOD_, $data );
        $data = self::str_replace_if_exist( '{SKINDIR}', str_replace( ROOT_DIR, '', CURRENT_SKIN ), $data );
        $data = self::str_replace_if_exist( '{HOME}', HOMEURL, $data );
        $data = self::str_replace_if_exist( '{CURRENT_USER_LOGIN}', CURRENT_USER_LOGIN, $data );
        $data = self::str_replace_if_exist( '{CURRENT_GROUP_ID}',   CURRENT_GROUP_ID, $data );
        $data = self::str_replace_if_exist( '{CURRENT_USER_ID}',    CURRENT_USER_ID, $data );
        $data = self::str_replace_if_exist( '{CURRENT_REGION_ID}',  CURRENT_REGION_ID, $data );
        $data = self::str_replace_if_exist( '{encoding}',           ENCODING, $data );
        $data = self::str_replace_if_exist( '{charset}',            CHARSET, $data );
        $data = self::str_replace_if_exist( '{CURR_URL}',           $_SERVER['REQUEST_URI'], $data );


        foreach( user::get_current_user_data_raw() as $uk => $uv )
        {
            $data = self::str_replace_if_exist( '{user:'.$uk.'}', $uv, $data );
        }

        $data = $this->parse_tags_access( $data );

        $data = $this->parse_tags_include( $data );
        $data = $this->parse_tags_login_nologin( $data );
        $data = $this->parse_tags_mod( $data ); 
        $data = $this->parse_tags_curr_user_info( $data );
        $data = $this->parse_tags_group( $data );
        $data = $this->parse_tags_region( $data );
        $data = $this->parse_table_select( $data );

        return $data;
    }

    private final function parse_tags_access( $data )
    {
        if( preg_match_all( '!\[access:(.+?)\](.+?)\[\/access\]!is', $data, $tag ) )
        {
            foreach( $tag[1] as $t )
            {
                $subtags = explode( '|', $t );
                $subtags = common::trim( $subtags );
                $has_access = false;

                foreach( $subtags as $subtag )
                {
                    $subtag = explode( ':', $subtag, 2 );
                    if( access::allow( $subtag[0], $subtag[1] ) )
                    {
                        $has_access = true;
                        break;
                    }
                }

                if( $has_access )
                {
                    $data = preg_replace( '!\[access:'.preg_quote($t,'!').'\](.+?)\[\/access\]!is', '$1', $data );
                }

                $data = preg_replace( '!\[access:'.preg_quote($t,'!').'\](.+?)\[\/access\]!is', '', $data );
            }
        }

        return $data;
    }

    private final function parse_tags_include( $data )
    {
        $tag = false;
        if( preg_match_all( '!\{\@include=([a-z0-9_\/]+?)\}!i', $data, $tag ) )
        {
            if( isset($tag[1]) && is_array($tag[1]) && count($tag[1]) )
            {
                foreach( $tag[1] as $key=>$elem )
                {
                    $elem = explode( '/', $elem );
                    $elem  = self::totranslit( $elem );
                    $elem  = implode( DS, $elem );
                    $file = $this->tpl_dir.DS.$elem.'.tpl';
                    if( !file_exists( $file ) ){ $elem = false; }

                    if( $elem && isset($tag[0][$key]) && $tag[0][$key] )
                    {
                        $data  = str_replace( $tag[0][$key], $this->load( $elem, false ), $data );
                    }
                }
            }
        }
        return $data;
    }

    private final function parse_tags_login_nologin( $data )
    {
        if( preg_match( '!\[(login|nologin)\](.+?)\[\/\1\]!is', $data ) )
        {
            $data = str_replace( (CURRENT_USER_ID?'[login]':'[nologin]'), '', $data );
            $data = str_replace( (CURRENT_USER_ID?'[/login]':'[/nologin]'), '', $data );

            $data = preg_replace( '!\[('.(CURRENT_USER_ID?'nologin':'login').')\](.+?)\[\/\1\]!is', '', $data );
        }
        return $data;
    }

    private final function parse_tags_mod( $data )
    {
        if( preg_match( '!\[(mod):(\w+?)\](.+?)\[\/\1\]!is', $data ) )
        {
            $data = preg_replace( '!\[(mod):('._MOD_.')\](.+?)\[\/\1\]!is', '$3', $data );
            $data = preg_replace( '!\[(mod):(\w+?)\](.+?)\[\/\1\]!is', '', $data );
        }
        return $data;
    }

    private final function parse_tags_curr_user_info( $data )
    {
        if( strpos( $data, '{curr.user:' ) )
        {
            if( !isset($GLOBALS['_user']) || !is_object($GLOBALS['_user'])){ self::err( '«м≥нну "_user" втрачено!' ); }

            foreach( $GLOBALS['_user']->get_curr_user_info()['user'] as $key => $value )
            {
                $data = str_replace( '{curr.user:'.$key.'}', self::htmlspecialchars(self::stripslashes($value)), $data );
            }
        }
        return $data;
    }

    private final function parse_table_select( $data )
    {
        while( preg_match( '!\{select:(\w+?)(:\d+?|)\}!i', $data, $match ) )
        {
            $table_name = common::strtolower( common::filter( isset($match[1])?$match[1]:false ) );
            $selected   = common::integer( isset($match[2])?$match[2]:false );
            $data = str_replace( $match[0], common::table2select( $table_name, $selected ), $data );
        }

        return $data;
    }

    private final function parse_tags_group( $data )
    {
        if( preg_match( '!\[(group:\d+?)\](.+?)\[\/\1\]!is', $data ) )
        {
          $data = str_replace( '[group:'.CURRENT_GROUP_ID.']', '', $data );
          $data = str_replace( '[/group:'.CURRENT_GROUP_ID.']', '', $data );
          $data = preg_replace( '!\[(group:\d+?)\](.+?)\[\/\1\]!is', '', $data );
        }

        if( preg_match( '!\[(nogroup:\d+?)\](.+?)\[\/\1\]!is', $data ) )
        {
          $data = str_replace( '[nogroup:'.CURRENT_GROUP_ID.']', '', $data );
          $data = str_replace( '[/nogroup:'.CURRENT_GROUP_ID.']', '', $data );
          $data = preg_replace( '!\[(nogroup:\d+?)\](.+?)\[\/\1\]!is', '', $data );
        }

        return $data;
    }

    private final function parse_tags_region( $data )
    {
        $matches = array();
        if( preg_match_all( '!\[(region):([0-9,]+?)\](.+?)\[\/\1\]!is', $data, $matches ) )
        {
            if( isset($matches['2']) && is_array($matches['2']) )
            {
                foreach( $matches['2'] as $region_id )
                {
                    $r = $region_id;
                    $region_id = explode( ',', $region_id );
                    $region_id = self::integer( $region_id );

                    if( in_array( CURRENT_REGION_ID, $region_id ) )
                    {
                        $data = preg_replace( '!\[(region):('.$r.')\](.+?)\[\/\1\]!is', '$3', $data );
                    }
                    else
                    {
                        $data = preg_replace( '!\[(region):('.$r.')\](.+?)\[\/\1\]!is', '', $data );
                    }
                }
            }
            $data = preg_replace( '!\[(region):([0-9,]+?)\](.+?)\[\/\1\]!is', '', $data );
        }
        return $data;
    }

}
