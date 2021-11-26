<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

require( CLASSES_DIR.DS.'class.common.php' );

//if( strpos( USER_IP, '192.168.137.' ) === false ){ echo 'Ресурс в розробці!'; exit; }

//////////////////////////////////////////////////////////////////////////////////////////

$_REQUEST   = common::filter( $_REQUEST );
$_COOKIE    = common::filter( $_COOKIE );
$_POST      = common::filter( $_POST );
$_GET       = common::filter( $_GET );

//////////////////////////////////////////////////////////////////////////////////////////

define( '_AJAX_',       isset($_REQUEST['ajax'])?       common::integer($_REQUEST['ajax']):false );
define( '_MOD_',        isset($_REQUEST['mod'])?        common::totranslit(common::trim($_REQUEST['mod'])):'main' );
define( '_SUBMOD_',     isset($_REQUEST['submod'])?     common::integer($_REQUEST['submod']):false );
define( '_ACTION_',     isset($_REQUEST['action'])?     common::integer($_REQUEST['action']):false );
define( '_SUBACTION_',  isset($_REQUEST['subaction'])?  common::integer($_REQUEST['subaction']):false );

//////////////////////////////////////////////////////////////////////////////////////////

require( CLASSES_DIR.DS.'class.db.php' );
require( CLASSES_DIR.DS.'class.cache.php' );
require( CLASSES_DIR.DS.'class.ajax.php' );
require( CLASSES_DIR.DS.'class.tpl.php' );
require( CLASSES_DIR.DS.'class.access.php' );
require( CLASSES_DIR.DS.'class.user.php' );
require( CLASSES_DIR.DS.'class.tags.php' );  
require( CLASSES_DIR.DS.'class.spr_manager.php' );
require( CLASSES_DIR.DS.'class.stock.php' );
require( CLASSES_DIR.DS.'class.dispersion.php' );
require( CLASSES_DIR.DS.'class.recipes.php' );
require( CLASSES_DIR.DS.'class.using.php' );
require( CLASSES_DIR.DS.'class.cooked.php' );
require( CLASSES_DIR.DS.'class.consume.php' );
require( CLASSES_DIR.DS.'class.stats.php' );
require( CLASSES_DIR.DS.'class.reactiv_consume.php' );
require( CLASSES_DIR.DS.'class.autocomplete.php' );
require( CLASSES_DIR.DS.'class.chat.php' );

//////////////////////////////////////////////////////////////////////////////////////////

require( CORE_DIR.DS.'dbconfig.php' );

//////////////////////////////////////////////////////////////////////////////////////////

user::start_session();

$tpl   = new tpl;
$_user = new user;

$_user->check_auth();

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('CURRENT_USER_ID') )   { common::err( 'Константа CURRENT_USER_ID не визачена!' ); }
if( !defined('CURRENT_REGION_ID') ) { common::err( 'Константа CURRENT_REGION_ID не визачена!' ); }
if( !defined('CURRENT_GROUP_ID') )  { common::err( 'Константа CURRENT_GROUP_ID не визачена!' ); }

//////////////////////////////////////////////////////////////////////////////////////////

if( _MOD_ == 'logout' ){ $_user->logout(); }
if( _MOD_ == 'clean_cache' && CURRENT_USER_ID ){ cache::clean(); exit; }
if( _MOD_ == 'ban' )
{
    ob_start();
        echo '$_SERVER = ';
        var_export( $_SERVER );
        echo "\n\n";
        echo '$_REQUEST = ';
        var_export( $_REQUEST );
    common::write_file( LOGS_DIR.DS.'banlist'.DS.USER_IP, ob_get_clean() );
    cache::clean();
    exit;
}

//////////////////////////////////////////////////////////////////////////////////////////

if( _AJAX_ )
{
    require( CORE_DIR.DS.'router.ajax.php' );
}
else
{
    if( CURRENT_USER_ID ){ require( CORE_DIR.DS.'router.static.php' ); }
    require( MODS_DIR.DS.'login.php' );
}

