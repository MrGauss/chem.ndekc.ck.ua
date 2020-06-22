<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

trait basic
{
    private static $HASH_SALT = 'kfNKs$mop*&(63hsd43Dlkvro83,sv-2l;mf2eav';

    public final function __call( $name, $arguments )
    {
        echo self::err( 'Method "'. $name. '" don\'t exist! '."\n" );
        exit;
    }

    public static function __callStatic($name, $arguments)
    {
        echo self::err( 'Âûçîâ ñòàòè÷åñêîãî ìåòîäà '.$name.' '. implode(', ', $arguments)."\n" );
        exit;
    }

    static public final function key_check( $text, $key )
    {
        return ( self::key_gen($text) ==  $key ) ? true : false;
    }

    static public final function key_gen( $text )
    {
        return sha1( strrev( md5( CURRENT_REGION_ID . DYNAMIC_SALT . CURRENT_USER_ID ).md5($text) ) );
    }

	static public final function err( $text )
	{
        trigger_error( ''.self::trim( $text ).'', E_USER_ERROR );
		exit;
	}

    public static function error( $error, $error_area = false )
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

    static public final function compare_perc( $a, $b )
    {
        if( !$a ){ return 100; }
        return round( ( 100 / self::float($a) ) * self::float( $b ), 0 );
    }

    static public final function ban( $text )
    {
        $file = LOGS_DIR.DS.'banlist'.DS.USER_IP;
        common::write_file( $file, 'BANNED!'."\n".$text."\n".'OMG...', true );
        exit;
    }

    static public final function to_nice_time( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data ) ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only!' ); }
        if( is_array($data) ){ return array_map( 'self::to_nice_time', $data ); }

        $time = array();
        $secd = 0;
        $mint = 0;
        $hour = 0;

        while( $data >= 3600 ){ $data = $data - 3600;   $hour++; }
        while( $data >= 60 ){   $data = $data - 60;     $mint++; }
        $secd = $data;

        return $hour.':'.$mint.':'.$secd;
    }

    static public final function db2html( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data ) ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::db2html', $data ); }

        $data = common::stripslashes( $data );
        
        $data = common::html_entity_decode( $data );
        $data = common::htmlspecialchars_decode( $data );

        $data = common::htmlentities($data);

        return $data;
    }

    static public final function filter_hash( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data ) ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::filter_hash', $data ); }

        $data = preg_replace( '!(\W+)!is', '', $data );
        $data = ( strlen( $data ) == 32 ) ? $data : false;
        return $data;
    }

    static public final function filter( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data ) ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::filter', $data ); }
        return self::trim( filter_var( $data, FILTER_UNSAFE_RAW, FILTER_FLAG_ENCODE_LOW | FILTER_FLAG_STRIP_BACKTICK | FILTER_FLAG_ENCODE_AMP ) );
    }

    static public final function htmlspecialchars_decode( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::htmlspecialchars_decode', $data ); }
        return htmlspecialchars_decode( $data, ENT_QUOTES | ENT_HTML5 );
    }

    static public final function float( $data )
    {
        if( !is_bool($data) && !is_null($data) && !is_numeric( $data ) && !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::float', $data ); }
        return floatval($data);
    }

	static public final function integer( $data )
	{
        if( !is_bool($data) && !is_null($data) && !is_numeric( $data ) && !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::integer', $data ); }
        $data = intval( $data, 10 );
        settype( $data, 'integer' );
        return $data;
	}

    static public final function string( $data )
    {
        if( !is_numeric( $data ) && !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::string', $data ); }
        return strval($data);
    }

    static public final function nice_number( $data, $b=1, $a=3 )
    {
        if( !is_numeric( $data ) && !is_scalar( $data )   ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string only! Given: '.gettype( $data ) ); }

        $data = explode( '.', $data, 2 );
        $data = self::integer( $data );

        if( array_sum( $data ) == 0 ){ return 0; }

        $data[1] = isset($data[1])?$data[1]:0;

        while( strlen($data[0]) < $b )
        {
            $data[0] = '0'.$data[0];
        }

        while( strlen($data[1]) < $a )
        {
            $data[1] = $data[1].'0';
        }

        return implode('.',$data);
    }

    static public final function strtotime( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::strtotime', $data ); }
        return strtotime( $data );
    }

    static public final function hash( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::hash', $data ); }
        return md5( sha1( sha1( $data ) . sha1( self::$HASH_SALT ) ) );
    }

    static public final function trim( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::trim', $data ); }
        return trim( $data );
    }

    static public final function stripslashes( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::stripslashes', $data ); }
        return stripslashes( $data );
    }

    static public final function strlen( $data )
    {
        if( !is_scalar( $data ) ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string only! Given: '.gettype( $data ) ); }
        return mb_strlen( $data, CHARSET ); ;
    }

    static public final function html_entity_decode( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::html_entity_decode', $data ); }
        return html_entity_decode( $data, ENT_QUOTES | ENT_HTML5, CHARSET ); ;
    }

    static public final function htmlspecialchars( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::htmlspecialchars', $data ); }
        return htmlspecialchars( $data, ENT_QUOTES | ENT_HTML5, CHARSET, true );;
    }

    static public final function htmlentities( $data = '' )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::htmlentities', $data ); }
        return htmlentities( $data, ENT_QUOTES | ENT_HTML5, CHARSET, true );
    }

    static public final function summ2arrays( $array_1, $array_2 )
    {
        if( !is_array($array_1) ){ $array_1 = array(); }
        if( !is_array($array_2) ){ $array_2 = array(); }

        $k = array_unique( array_merge( array_keys( $array_1 ), array_keys( $array_2 ) ) );
        $ARR = array();

        foreach( $k as $key )
        {
            if( !isset($ARR[$key]) ){ $ARR[$key] = 0; }
            if( isset( $array_1[$key] ) ){ $ARR[$key] = $ARR[$key] + self::integer( $array_1[$key] ); }
            if( isset( $array_2[$key] ) ){ $ARR[$key] = $ARR[$key] + self::integer( $array_2[$key] ); }
            $ARR[$key] = self::integer( $ARR[$key] );
        }

        return $ARR;
    }

    static public final function strtoupper( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::strtoupper', $data ); }
        return mb_strtoupper( $data, CHARSET );
    }

    static public final function strtolower( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::strtolower', $data ); }
        return mb_strtolower( $data, CHARSET );
    }

    static public final function safesql( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::safesql', $data ); }
        return pg_escape_string( $data );
    }

    static public final function urlencode( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::urlencode', $data ); }
        return urlencode( $data );
    }

    static public final function urldecode( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::urldecode', $data ); }
        return urldecode( $data );
    }
    static public final function utf2win( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::utf2win', $data ); }
        return mb_convert_encoding( $data, 'cp1251', 'utf-8' );
    }

    static public final function win2utf( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::win2utf', $data ); }
        return mb_convert_encoding( $data, 'utf-8', 'cp1251' );
    }

    static final public function encode_string( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::encode_string', $data ); }
        return self::urlencode( base64_encode( strrev( base64_encode( $data ) ) ) );
    }

    static final public function decode_string( $data )
    {
        if( !is_scalar( $data ) && !is_array( $data )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only! Given: '.gettype( $data ) ); }
        if( is_array($data) ){ return array_map( 'self::decode_string', $data ); }
        return base64_decode( strrev( base64_decode( self::urldecode( $data ) ) ) ); ;
    }

    static public final function en_date( $date, $format = 'd.m.Y H:i:s' )
    {
        if( $date && !is_scalar( $date ) )
        {
            self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string only!' );
        }
        $date = strtotime( $date );
        $date = intval( $date );
        $date = date( $format, $date );
        return $date;
    }

    static public final function totranslit( $str )
    {
        if( !is_scalar( $str ) && !is_array( $str )  ){ self::err( ''.__CLASS__.'::'.__METHOD__.' accepts string or array only!' ); }
        if( is_array($str) ){ return array_map( 'self::totranslit', $str ); }

        $str = self::strtolower( $str );
        $rp = array();
        $rp[] = array( 'àáâãäå¸çèéêëìíîïðñòóôõöüûý³ ', 'abvgdeezijklmnoprstufhc\'yei_' );
        $rp[] = array( 'ÀÁÂÃÄÅ¸ÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖÜÛÝ² ', 'ABVGDEEZIJKLMNOPRSTUFHC\'YEI_' );

        for( $i=0; $i<count($rp); $i++ ){ $str = strtr( $str, $rp[$i][0], $rp[$i][1] ); }

        $str = str_replace( 'æ', 'zh', $str );
        $str = str_replace( '÷', 'ch', $str );
        $str = str_replace( 'ø', 'sh', $str );
        $str = str_replace( 'ù', 'shh', $str );
        $str = str_replace( 'ú', '\'', $str );
        $str = str_replace( 'þ', 'yu', $str );
        $str = str_replace( 'ÿ', 'ya', $str );
        $str = str_replace( 'º', 'ye', $str );
        $str = str_replace( 'Æ', 'ZH', $str );
        $str = str_replace( '×', 'CH', $str );
        $str = str_replace( 'Ø', 'SH', $str );
        $str = str_replace( 'Ù', 'SHH', $str );
        $str = str_replace( 'Ú', '`', $str );
        $str = str_replace( 'Þ', 'YU', $str );
        $str = str_replace( 'ß', 'YA', $str );
        $str = str_replace( 'ª', 'YE', $str );

        $str = self::strtolower( $str );

        $str = self::trim( strip_tags( $str ) );
        $str = preg_replace( '![^a-z0-9\_\-]+!mi', '', $str );
        $str = preg_replace( '![.]+!i', '.', $str );
        $str = self::strtolower( $str );

        return $str;
    }

    static protected final function read_file( $filename )
    {
        if( !file_exists($filename) ){  return false; }
        if( !filesize($filename) ){     return false; }

        $fop = fopen( $filename, 'rb' );
        $data = fread( $fop, filesize( $filename ) );
        fclose( $fop );
        return $data;
    }

    public final static function log_wrong_pass()
    {
        $file = CACHE_DIR.DS.'ban-'.USER_IP;
        common::write_file( $file, '1', true );

        if( strlen( self::read_file( $file ) ) > 5 )
        {
            unlink( $file );
            $file = LOGS_DIR.DS.'banlist'.DS.USER_IP;
            common::write_file( $file, '1', true );
        }
    }

    static public final function write_file( $filename, $data = false, $log = false )
    {
        if( !file_exists($filename) ){ fclose( fopen($filename, 'a' ) ); }

        if( $log == true ){ $fop =  fopen( $filename, 'a' ); }
        else{ $fop =  fopen( $filename, 'w' ); }

        if( flock($fop, LOCK_EX ) )
        {
          fwrite( $fop, $data );
          fflush( $fop );
          flock( $fop, LOCK_UN );
        }

        fclose( $fop );

        return true;
    }

}

