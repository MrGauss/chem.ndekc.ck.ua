<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )          { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) )   { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }
if( !trait_exists( 'raw_stats' ) )    { require( CLASSES_DIR.DS.'trait.raw_stats.php' ); }

class stats
{
    use basic, spr, db_connect, raw_stats;

    public final function get_stats_consume_by_stock_id_html( $filters = array() )
    {
        $data = $this->get_stats_consume_by_stock_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw( $filters );
        $units   = ( new spr_manager( 'units' )   )->get_raw( $filters );

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $stock_id => $stock_data )
        {
            $tpl->load( 'stats_consume/by_stock_id_line' );

            foreach( $stock_data as $k=>$v )
            {
                if( is_array($v) ){ continue; }
                $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            }

            if( isset( $reagent[$stock_data['reagent_id']] ) && is_array($reagent[$stock_data['reagent_id']]) )
            {
                foreach( $reagent[$stock_data['reagent_id']] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:reagent:'.$k.'}', common::db2html( $v ) );
                }

                if( isset( $units[$reagent[$stock_data['reagent_id']]['units_id']] ) && is_array($units[$reagent[$stock_data['reagent_id']]['units_id']]) )
                {
                    foreach( $units[$reagent[$stock_data['reagent_id']]['units_id']] as $k=>$v )
                    {
                        if( is_array($v) ){ continue; }
                        $tpl->set( '{tag:units:'.$k.'}', common::db2html( $v ) );
                    }
                }

                $reagent[$stock_data['reagent_id']]['units_id'];
            }

            $tpl->set( '{I}', $I-- );

            $tpl->compile( 'stats_consume/by_stock_id_line' );
        }

        return $tpl->result( 'stats_consume/by_stock_id_line' );
    }

    public final function get_stats_consume_by_reagent_id_html( $filters = array() )
    {
        $data = $this->get_stats_consume_by_reagent_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw( $filters );
        $units   = ( new spr_manager( 'units' )   )->get_raw( $filters );

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $reagent_id => $reagent_data )
        {
            $tpl->load( 'stats_consume/by_reagent_id_line' );

            foreach( $reagent_data as $k=>$v )
            {
                if( is_array($v) ){ continue; }
                $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            }

            if( isset( $reagent[$reagent_id] ) && is_array($reagent[$reagent_id]) )
            {
                foreach( $reagent[$reagent_id] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:reagent:'.$k.'}', common::db2html( $v ) );
                }

                if( isset( $units[$reagent[$reagent_id]['units_id']] ) && is_array($units[$reagent[$reagent_id]['units_id']]) )
                {
                    foreach( $units[$reagent[$reagent_id]['units_id']] as $k=>$v )
                    {
                        if( is_array($v) ){ continue; }
                        $tpl->set( '{tag:units:'.$k.'}', common::db2html( $v ) );
                    }
                }
            }

            $tpl->set( '{I}', $I-- );

            $tpl->compile( 'stats_consume/by_reagent_id_line' );
        }

        return $tpl->result( 'stats_consume/by_reagent_id_line' );
    }

    public final function get_stats_reactiv_consume_by_reagent_id_html( $filters = array() )
    {
        $data = $this->get_stats_reactiv_consume_by_reagent_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $skin = 'stats_reactiv_consume/by_recipe_id_line';

        $recipes = ( new recipes )->get_raw();
        $units   = ( new spr_manager( 'units' ) )->get_raw( $filters );

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $recipe_id => $reactiv_data )
        {
            $tpl->load( $skin );

            foreach( $reactiv_data as $k=>$v )
            {
                if( is_array($v) ){ continue; }
                $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            }

            if( isset( $recipes[$recipe_id] ) && is_array($recipes[$recipe_id]) )
            {
                foreach( $recipes[$recipe_id] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:recipe:'.$k.'}', common::db2html( $v ) );
                }

                if( isset( $units[$recipes[$recipe_id]['units_id']] ) && is_array($units[$recipes[$recipe_id]['units_id']]) )
                {
                    foreach( $units[$recipes[$recipe_id]['units_id']] as $k=>$v )
                    {
                        if( is_array($v) ){ continue; }
                        $tpl->set( '{tag:units:'.$k.'}', common::db2html( $v ) );
                    }
                }
            }

            $tpl->set( '{I}', $I-- );
            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_stats_consume_by_purpose_id_html( $filters = array() )
    {
        $data = $this->get_stats_consume_by_purpose_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $skin = 'stats_consume/by_purpose_id_line';

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw( $filters );
        $units   = ( new spr_manager( 'units' )   )->get_raw( $filters );
        $purpose = ( new spr_manager( 'purpose' ) )->get_raw( $filters );

        $tpl = new tpl;

        $table = array();
        foreach( $data as $purpose_id => $purpose_data )
        {
            $I = count( $purpose_data );

            $first_line = true;
            $rows = 0;

            $curr_count_summ = 0;
            foreach( $purpose_data as $reagent_id => $reagent_data )
            {
                $curr_count_summ = $curr_count_summ + $reagent_data['consume_count'];
            }

            foreach( $purpose_data as $reagent_id => $reagent_data )
            {
                $rows++;

                $tpl->load( $skin );

                if( $first_line )
                {
                    $tpl->set_block( '!\[first\](.+?|)\[\/first\]!', '$1' );
                    $tpl->set_block( '!\[not-first\](.+?|)\[\/not-first\]!', '' );
                    $tpl->set( '{consume_count:summ}', $curr_count_summ );

                }
                else
                {
                    $tpl->set_block( '!\[first\](.+?|)\[\/first\]!', '' );
                    $tpl->set_block( '!\[not-first\](.+?|)\[\/not-first\]!', '$1' );
                    $tpl->set( '{consume_count:summ}', '' );
                }

                foreach( $reagent_data as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
                }

                foreach( $reagent[$reagent_id] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:reagent:'.$k.'}', common::db2html( $v ) );
                }

                foreach( $purpose[$purpose_id] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:purpose:'.$k.'}', common::db2html( $v ) );
                }

                foreach( $units[$reagent[$reagent_id]['units_id']] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:units:'.$k.'}', common::db2html( $v ) );
                }

                $tpl->set( '{I}', $I-- );
                $tpl->compile( $skin );

                $first_line = false;
            }

            $table[] = str_replace( '{rows}', $rows, $tpl->result( $skin ) );
        }

        $table = '<colgroup span="'.count($table).'"></colgroup>'."\n".'<tbody>'.implode( '</tbody><tbody>', $table ).'</tbody>';

        return $table;
    }

    public final function get_stats_consume_dynamics_html( $filters = array() )
    {
        $data = $this->get_stats_consume_dynamics_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw( $filters );
        $units   = ( new spr_manager( 'units' )   )->get_raw( $filters );

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $reagent_id => $reagent_data )
        {
            $tpl->load( 'stats_consume_dynamic/table_line' );

            foreach( $reagent_data as $k=>$v )
            {
                if( is_array($v) ){ continue; }
                $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            }

            if( isset( $reagent[$reagent_id] ) && is_array($reagent[$reagent_id]) )
            {
                foreach( $reagent[$reagent_id] as $k=>$v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{tag:reagent:'.$k.'}', common::db2html( $v ) );
                }

                if( isset( $units[$reagent[$reagent_id]['units_id']] ) && is_array($units[$reagent[$reagent_id]['units_id']]) )
                {
                    foreach( $units[$reagent[$reagent_id]['units_id']] as $k=>$v )
                    {
                        if( is_array($v) ){ continue; }
                        $tpl->set( '{tag:units:'.$k.'}', common::db2html( $v ) );
                    }
                }
            }

            $tpl->set( '{I}', $I-- );

            $tpl->compile( 'stats_consume_dynamic/table_line' );
        }

        return $tpl->result( 'stats_consume_dynamic/table_line' );
    }

}

