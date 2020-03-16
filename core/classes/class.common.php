<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) ){ require( CLASSES_DIR.DS.'trait.basic.php' ); }

class common
{
	use basic;

    static public final function table2select( $table_name, $selected )
    {
        if( $table_name == 'user' )          { return user::get_select( common::integer($selected) ); }
        if( $table_name == 'stock' )         { return stock::get_select( common::integer($selected) ); }
        if( $table_name == 'reagent' )       { return spr_manager::make_select( 'reagent',          common::integer($selected) ); }
        if( $table_name == 'clearence' )     { return spr_manager::make_select( 'clearence',        common::integer($selected) ); }
        if( $table_name == 'reagent_state' ) { return spr_manager::make_select( 'reagent_state',    common::integer($selected) ); }
        if( $table_name == 'danger_class' )  { return spr_manager::make_select( 'danger_class',     common::integer($selected) ); }

        return false;
    }
}