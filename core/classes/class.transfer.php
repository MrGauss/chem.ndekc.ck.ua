<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )          { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) )   { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class transfer
{
    use basic, spr, db_connect;

    public final function editor( $id = 0 )
    {
        access::check( 'stock', 'view' );

        $skin = 'transfer/editor';

        $tpl = new tpl;

        $tpl->load( $skin );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function save( $id = 0 )
    {

    }

    public final function remove( $id = 0 )
    {

    }

    public final function get_raw( $filters = array() )
    {

    }

}