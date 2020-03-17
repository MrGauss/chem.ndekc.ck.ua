<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

switch ( _MOD_ )
{
    case 'spr_clearence':   define( 'TABLE_AREA', 'clearence' ); break;
    case 'spr_dangerous':   define( 'TABLE_AREA', 'danger_class' ); break;
    case 'spr_reactives':   define( 'TABLE_AREA', 'reagent' ); break;
    case 'spr_states':      define( 'TABLE_AREA', 'reagent_state' ); break;
    case 'spr_purpose':     define( 'TABLE_AREA', 'purpose' ); break;
    case 'spr_units':       define( 'TABLE_AREA', 'units' ); break;

    default: common::err( 'Дія невідома!' );
}