<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )          { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) )   { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class stats
{
    use basic, spr, db_connect;

    public final function get_stats_consume_by_stock_id_html( $filters = array() )
    {
        $data = $this->get_stats_consume_by_stock_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();

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

    private final function get_stats_consume_by_stock_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']      = 'consume.date     > \'1970-01-01\'::date';
        $WHERE['stock.id']          = 'stock.id         > \'0\'::integer';
        $WHERE['stock.group_id']    = 'stock.group_id   = '.CURRENT_GROUP_ID.'';

        $filters = is_array($filters) ? $filters : array();
        if( isset($filters['consume_date:from']) )
        {
            $filters['consume_date:from'] = common::en_date( $filters['consume_date:from'], 'Y-m-d' );
            $WHERE['consume.date:from']      = 'consume.date >= \'' . $this->db->safesql( $filters['consume_date:from'] ) . '\'::date';
        }

        if( isset($filters['consume_date:to']) )
        {
            $filters['consume_date:to'] = common::en_date( $filters['consume_date:to'], 'Y-m-d' );
            $WHERE['consume.date:to']      = 'consume.date <= \'' . $this->db->safesql( $filters['consume_date:to'] ) . '\'::date';
        }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
                    SELECT
                        stock.id,
                        SUM( consume.quantity )         as consume_quantity,
                        SUM( stock.quantity_inc )       as stock_quantity_inc,
                        SUM( stock.quantity_left )      as stock_quantity_left,
                        SUM( dispersion.quantity_inc )  as dispersion_quantity_inc,
                        SUM( dispersion.quantity_left ) as dispersion_quantity_left,
                        stock.reagent_number,
                        stock.reagent_id
                    FROM
                        consume
                        LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id )
                        LEFT JOIN stock ON( stock.id = dispersion.stock_id AND dispersion.group_id = stock.group_id )
                        LEFT JOIN reagent ON( reagent.id = stock.reagent_id )
                    '.$WHERE.'
                    GROUP BY
                        stock.id
                    ORDER BY
                        consume_quantity DESC;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;

    }

    //////////////////////

    public final function get_stats_consume_by_reagent_id_html( $filters = array() )
    {
        $data = $this->get_stats_consume_by_reagent_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();

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

    private final function get_stats_consume_by_reagent_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']      = 'consume.date > \'1970-01-01\'::date';
        $WHERE['stock.id']          = 'stock.id > \'0\'::integer';
        $WHERE['stock.group_id']    = 'stock.group_id = '.CURRENT_GROUP_ID.'';

        $filters = is_array($filters) ? $filters : array();
        if( isset($filters['consume_date:from']) )
        {
            $filters['consume_date:from'] = common::en_date( $filters['consume_date:from'], 'Y-m-d' );
            $WHERE['consume.date:from']      = 'consume.date >= \'' . $this->db->safesql( $filters['consume_date:from'] ) . '\'::date';
        }

        if( isset($filters['consume_date:to']) )
        {
            $filters['consume_date:to'] = common::en_date( $filters['consume_date:to'], 'Y-m-d' );
            $WHERE['consume.date:to']      = 'consume.date <= \'' . $this->db->safesql( $filters['consume_date:to'] ) . '\'::date';
        }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
            SELECT
                reagent.id,
                SUM( consume.quantity ) 					as consume_quantity,
                SUM( stock.quantity_inc ) 				as stock_quantity_inc,
                SUM( stock.quantity_left ) 				as stock_quantity_left,
                SUM( dispersion.quantity_inc ) 		as dispersion_quantity_inc,
                SUM( dispersion.quantity_left ) 	as dispersion_quantity_left

            FROM
                consume
                LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id )
                LEFT JOIN stock ON( stock.id = dispersion.stock_id AND dispersion.group_id = stock.group_id )
                LEFT JOIN reagent ON( reagent.id = stock.reagent_id )
            '.$WHERE.'
            GROUP BY
                reagent.id
            ORDER BY
                consume_quantity DESC;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }

    //////////////////////

    public final function get_stats_reactiv_consume_by_reagent_id_html( $filters = array() )
    {
        $data = $this->get_stats_reactiv_consume_by_reagent_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $skin = 'stats_reactiv_consume/by_recipe_id_line';

        $recipes = ( new recipes )->get_raw();
        $units   = ( new spr_manager( 'units' ) )->get_raw();

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

    private final function get_stats_reactiv_consume_by_reagent_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['reactiv_consume.date']  = 'reactiv_consume.date > \'1970-01-01\'::date';
        $WHERE['reactiv.hash']          = 'reactiv.hash != \'\'';
        $WHERE['reactiv.group_id']      = 'reactiv.group_id = '.CURRENT_GROUP_ID.'';

        $filters = is_array($filters) ? $filters : array();
        if( isset($filters['consume_date:from']) )
        {
            $filters['consume_date:from'] = common::en_date( $filters['consume_date:from'], 'Y-m-d' );
            $WHERE['reactiv_consume.date:from']      = 'reactiv_consume.date >= \'' . $this->db->safesql( $filters['consume_date:from'] ) . '\'::date';
        }

        if( isset($filters['consume_date:to']) )
        {
            $filters['consume_date:to'] = common::en_date( $filters['consume_date:to'], 'Y-m-d' );
            $WHERE['reactiv_consume.date:to']      = 'reactiv_consume.date <= \'' . $this->db->safesql( $filters['consume_date:to'] ) . '\'::date';
        }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
            SELECT
                reactiv.reactiv_menu_id,
                SUM( reactiv_consume.quantity ) as reactiv_consume_quantity,
                SUM( reactiv.quantity_inc ) as reactiv_quantity_inc,
                SUM( reactiv.quantity_left ) as reactiv_quantity_left

            FROM
                reactiv_consume
                LEFT JOIN reactiv ON( reactiv.hash = reactiv_consume.reactiv_hash )
            '.$WHERE.'
            GROUP BY reactiv.reactiv_menu_id
            ORDER BY reactiv_consume_quantity DESC;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['reactiv_menu_id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;

    }

}
















