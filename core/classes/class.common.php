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
        if( $table_name == 'reagent' )       { return reagent::get_select( common::integer($selected) ); }
        if( $table_name == 'clearence' )     { return reagent::get_clearence_select( common::integer($selected) ); }
        if( $table_name == 'reagent_state' ) { return reagent::get_state_select( common::integer($selected) ); }
        if( $table_name == 'danger_class' )  { return reagent::get_danger_class_select( common::integer($selected) ); }

        return false;
    }
}