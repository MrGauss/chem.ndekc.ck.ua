<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

trait raw_stats
{
    private function get_stats_consume_by_stock_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']      = 'consume.date     > \'1970-01-01\'::date';
        $WHERE['stock.id']          = 'stock.id         > \'0\'::integer';
        $WHERE['stock.group_id']    = 'stock.group_id   = '.CURRENT_GROUP_ID.'';
        $WHERE['groups.region_id']  = 'groups.region_id = '.CURRENT_REGION_ID.'';

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

        if( isset($filters['precursor_only']) && common::integer($filters['precursor_only']) )
        {
            $WHERE['precursor_only']   = 'reagent.is_precursor = 1';
        }

        if( isset($filters['by_region']) && common::integer($filters['by_region']) != 0 )
        {
            $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
            $WHERE['stock.group_id'] = false;
            unset( $WHERE['stock.group_id'] );
        }

        $COUNTER = $WHERE['consume.date'].''
                        .(isset($WHERE['consume.date:from'])?' AND '.$WHERE['consume.date:from']:'')
                        .(isset($WHERE['consume.date:to'])?' AND '.$WHERE['consume.date:to']:'');
        $COUNTER = ''.$COUNTER.' ';

        if( isset($WHERE['consume.date:from']) ){ unset( $WHERE['consume.date:from'] ); }
        if( isset($WHERE['consume.date:to']) ){ unset( $WHERE['consume.date:to'] ); }
        if( isset($WHERE['consume.date']) ){ unset( $WHERE['consume.date'] ); }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
            SELECT
                DISTINCT ON( stock.id ) stock.id,
                stock.reagent_id,
                stock.reagent_number,
                ( SELECT SUM( s2.quantity_inc ) FROM stock as s2 WHERE s2.id = stock.id ) as stock_quantity_inc,
                ( SELECT SUM( s2.quantity_left ) FROM stock as s2 WHERE s2.id = stock.id ) as stock_quantity_left,
                ( SELECT SUM( dispersion.quantity_inc ) FROM dispersion WHERE dispersion.stock_id = stock.id ) as dispersion_quantity_inc,
                ( SELECT SUM( dispersion.quantity_left ) FROM dispersion WHERE dispersion.stock_id = stock.id ) as dispersion_quantity_left,
                ( SELECT SUM( consume.quantity ) FROM consume LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id ) WHERE dispersion.stock_id = stock.id ) as consume_quantity_full,
                ( SELECT SUM( consume.quantity ) FROM consume LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id ) WHERE dispersion.stock_id = stock.id AND '.$COUNTER.' ) as consume_quantity,
                ( SELECT count( DISTINCT consume.hash ) FROM consume LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id ) WHERE dispersion.stock_id = stock.id AND '.$COUNTER.' ) as consume_count
            FROM
                stock
                LEFT JOIN reagent ON( stock.reagent_id = reagent.id )
                LEFT JOIN groups ON( groups.id = stock.group_id )
            '.$WHERE.'
            ORDER BY stock.id;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $rn = $row['reagent_number'];
            $row = common::float( $row );
            $row['reagent_number'] = $rn;
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }


    private function get_stats_consume_by_reagent_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']      = 'consume.date > \'1970-01-01\'::date';
        $WHERE['stock.id']          = 'stock.id > \'0\'::integer';
        $WHERE['stock.group_id']    = 'stock.group_id = '.CURRENT_GROUP_ID.'';
        $WHERE['groups.region_id']  = 'groups.region_id = '.CURRENT_REGION_ID.'';

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

        if( isset($filters['precursor_only']) && common::integer($filters['precursor_only']) )
        {
            $WHERE['precursor_only']   = 'reagent.is_precursor = 1';
        }

        if( isset($filters['by_region']) && common::integer($filters['by_region']) != 0 )
        {
            $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
            $WHERE['stock.group_id'] = false;
            unset( $WHERE['stock.group_id'] );
        }

        $COUNTER = $WHERE['consume.date'].''
                        .(isset($WHERE['consume.date:from'])?' AND '.$WHERE['consume.date:from']:'')
                        .(isset($WHERE['consume.date:to'])?' AND '.$WHERE['consume.date:to']:'');
        $COUNTER = ' '.$COUNTER.' ';

        if( isset($WHERE['consume.date:from']) ){ unset( $WHERE['consume.date:from'] ); }
        if( isset($WHERE['consume.date:to']) ){ unset( $WHERE['consume.date:to'] ); }
        if( isset($WHERE['consume.date']) ){ unset( $WHERE['consume.date'] ); }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
            SELECT
                DISTINCT ON( stock.reagent_id ) stock.reagent_id,
                stock.reagent_number,
                ( SELECT SUM( s2.quantity_inc ) FROM stock as s2 WHERE s2.reagent_id = stock.reagent_id ) as stock_quantity_inc,
                ( SELECT SUM( s2.quantity_left ) FROM stock as s2 WHERE s2.reagent_id = stock.reagent_id ) as stock_quantity_left,
                ( SELECT SUM( dispersion.quantity_inc ) FROM dispersion WHERE dispersion.stock_id = stock.id ) as dispersion_quantity_inc,
                ( SELECT SUM( dispersion.quantity_left ) FROM dispersion WHERE dispersion.stock_id = stock.id ) as dispersion_quantity_left,
                ( SELECT SUM( consume.quantity ) FROM consume LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id ) WHERE dispersion.stock_id = stock.id ) as consume_quantity_full,
                ( SELECT SUM( consume.quantity ) FROM consume LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id ) WHERE dispersion.stock_id = stock.id AND '.$COUNTER.' ) as consume_quantity,
                ( SELECT count( DISTINCT consume.hash ) FROM consume LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id ) WHERE dispersion.stock_id = stock.id AND '.$COUNTER.' ) as consume_count
            FROM
                stock
                LEFT JOIN reagent ON( stock.reagent_id = reagent.id )
                LEFT JOIN groups ON( groups.id = stock.group_id )
            '.$WHERE.'
            ORDER BY stock.reagent_id;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row = common::float( $row );
            $data[$row['reagent_id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }


    private function get_stats_reactiv_consume_by_reagent_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['reactiv_consume.date']  = 'reactiv_consume.date > \'1970-01-01\'::date';
        $WHERE['reactiv.hash']          = 'reactiv.hash != \'\'';
        $WHERE['reactiv.group_id']      = 'reactiv.group_id = '.CURRENT_GROUP_ID.'';
        $WHERE['groups.region_id']      = 'groups.region_id = '.CURRENT_REGION_ID.'';

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

        if( isset($filters['by_region']) && common::integer($filters['by_region']) != 0 )
        {
            $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
            $WHERE['stock.group_id'] = false;
            unset( $WHERE['stock.group_id'] );
        }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
            SELECT
                reactiv.reactiv_menu_id,
                COUNT( reactiv_consume.hash ) as consume_count,
                SUM( reactiv_consume.quantity ) as reactiv_consume_quantity,
                ( SUM( reactiv.quantity_inc ) / COUNT( reactiv_consume.hash ) ) as reactiv_quantity_inc,
                ( SUM( reactiv.quantity_left ) / COUNT( reactiv_consume.hash ) ) as reactiv_quantity_left
            FROM
                reactiv_consume
                LEFT JOIN reactiv ON( reactiv.hash = reactiv_consume.reactiv_hash )
                LEFT JOIN groups ON( groups.id = reactiv.group_id )

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
            $row['reactiv_consume_quantity']    = common::float( $row['reactiv_consume_quantity'] );
            $row['reactiv_quantity_inc']        = common::float( $row['reactiv_quantity_inc'] );
            $row['reactiv_quantity_left']       = common::float( $row['reactiv_quantity_left'] );
            $data[$row['reactiv_menu_id']]      = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }

    public final function get_stats_consume_by_purpose_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']       = 'consume.date     > \'1970-01-01\'::date';
        $WHERE['stock.id']           = 'stock.id         > \'0\'::integer';
        $WHERE['stock.group_id']     = 'stock.group_id   = '.CURRENT_GROUP_ID.'';
        $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
        $WHERE['using.purpose_id']   = '"using".purpose_id > 0';

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

        if( isset($filters['precursor_only']) && common::integer($filters['precursor_only']) )
        {
            $WHERE['precursor_only']   = 'reagent.is_precursor = 1';
        }

        if( isset($filters['by_region']) && common::integer($filters['by_region']) != 0 )
        {
            $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
            $WHERE['stock.group_id'] = false;
            unset( $WHERE['stock.group_id'] );
        }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( ' AND ', $WHERE ); }

        $SQL = '
            SELECT
                "using".purpose_id,
                stock.reagent_id,
                SUM( consume.quantity ) as consume_quantity,
                COUNT( consume.hash ) as consume_count
            FROM
                consume
                LEFT JOIN consume_using ON( consume_using.consume_hash = consume.hash )
                LEFT JOIN "using" ON( "using".hash = consume_using.using_hash )
                LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id )
                LEFT JOIN stock	ON( dispersion.stock_id = stock.id )
                LEFT JOIN reagent ON( stock.reagent_id = reagent.id )
                LEFT JOIN groups ON( groups.id = stock.group_id AND groups.id = dispersion.group_id AND groups.id = "using".group_id )
            '.$WHERE.'
            GROUP BY "using".purpose_id, stock.reagent_id
            ORDER BY  consume_quantity DESC
            ;
        '.QUERY_CACHABLE;

        // echo $SQL; exit;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            if( !isset($data[$row['purpose_id']]) ){ $data[$row['purpose_id']] = array(); }
            if( !isset($data[$row['purpose_id']][$row['reagent_id']]) ){ $data[$row['purpose_id']][$row['reagent_id']] = array(); }

            $row['consume_quantity']    = common::float( $row['consume_quantity'] );

            $data[$row['purpose_id']][$row['reagent_id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }


    public final function get_stats_consume_dynamics_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']       = 'consume.date     > \'1970-01-01\'::date';
        $WHERE['stock.id']           = 'stock.id         > \'0\'::integer';
        $WHERE['stock.group_id']     = 'stock.group_id   = '.CURRENT_GROUP_ID.'';
        $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
        $WHERE['stock.reagent_id']   = 'stock.reagent_id > 0';

        $filters = is_array($filters) ? $filters : array();
        $filters['year_correction'] = common::integer( isset($filters['year_correction']) ? $filters['year_correction'] : 0 );

        $WHERE['consume.date:year_from']    = 'consume.date >= date_trunc( \'year\', NOW() '.($filters['year_correction']>=0?'+':'-').' INTERVAL \''. ( abs($filters['year_correction']) ) .' year\' )';
        $WHERE['consume.date:year_to']      = 'consume.date < date_trunc( \'year\', NOW() '. ( ($filters['year_correction']>=0?'+':'-').' INTERVAL \''. ( abs( 1 + $filters['year_correction'] ) ) .' year\' '  ) .')';

        if( isset($filters['by_region']) && common::integer($filters['by_region']) != 0 )
        {
            $WHERE['groups.region_id']   = 'groups.region_id = '.CURRENT_REGION_ID.'';
            $WHERE['stock.group_id'] = false;
            unset( $WHERE['stock.group_id'] );
        }

        if( is_array($WHERE) && count($WHERE) ){ $WHERE = 'WHERE '.implode( "\n".' AND ', $WHERE ); }

        $SELECTORS = array();
        for( $i = 1; $i<=12; $i++ )
        {
            $SELECTORS[] = 'SUM( ( ( extract( \'month\' from consume.date ) = '.$i.' )::INTEGER * consume.quantity  )::FLOAT ) as consume_quantity_'.$i;
            $SELECTORS[] = 'SUM( ( ( extract( \'month\' from consume.date ) = '.$i.' )::INTEGER )::FLOAT ) as consume_count_'.$i;
        }

        $SELECTORS = implode( ", \n\t", $SELECTORS );

        $SQL = '
            SELECT
                stock.reagent_id,
                SUM( consume.quantity ) as consume_quantity,
                '.$SELECTORS.'
            FROM
                consume
                LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id )
                LEFT JOIN stock ON( stock.id = dispersion.stock_id )
                LEFT JOIN groups ON( groups.id = stock.group_id AND groups.id = dispersion.group_id )
            '.$WHERE.'
            GROUP BY stock.reagent_id
            ;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['consume_quantity']    = common::float( $row['consume_quantity'] );

            for( $i = 1; $i<=12; $i++ ){ $row['consume_quantity_'.$i] = common::float( $row['consume_quantity_'.$i] ); }
            $data[common::integer($row['reagent_id'])] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }



}

