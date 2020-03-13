<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

$_ajax_result = array
           (
             'error' => 0,
             'error_text'     => '',
           );

class ajax
{
  use basic;

  public static $_ajax_result = array
           (
             'error' => 0,
             'error_text'     => '',
           );

  public final static function ch_result()
  {
    if( !isset($GLOBALS['_ajax_result']) && !is_array($GLOBALS['_ajax_result']) )
    {
      $GLOBALS['_ajax_result'] = self::$_ajax_result;
    }
  }

  public final static function result()
  {
    self::ch_result();

    $result = &$GLOBALS['_ajax_result'];
    $result = self::win2utf( $result );
    $result = json_encode( $result );

    return $result;
  }

  public final static function set_error( $id = 1, $text )
  {
    self::set_data( 'error', $id );
    self::set_data( 'error_text', $text );
    return true;
  }

  public final static function set_data( $name, $data )
  {
    self::ch_result();
    $result = &$GLOBALS['_ajax_result'];

    $result[$name] = common::string( $data );
    return true;
  }
}
