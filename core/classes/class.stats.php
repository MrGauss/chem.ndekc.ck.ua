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
                COUNT( reactiv_consume.hash ) as consume_count,
                SUM( reactiv_consume.quantity ) as reactiv_consume_quantity,
                ( SUM( reactiv.quantity_inc ) / COUNT( reactiv_consume.hash ) ) as reactiv_quantity_inc,
                ( SUM( reactiv.quantity_left ) / COUNT( reactiv_consume.hash ) ) as reactiv_quantity_left
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

    //////////////////////

    public final function get_stats_consume_by_purpose_id_html( $filters = array() )
    {
        $data = $this->get_stats_consume_by_purpose_id_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $skin = 'stats_consume/by_purpose_id_line';

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();
        $purpose = ( new spr_manager( 'purpose' ) )->get_raw();

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

    public final function get_stats_consume_by_purpose_id_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']       = 'consume.date     > \'1970-01-01\'::date';
        $WHERE['stock.id']           = 'stock.id         > \'0\'::integer';
        $WHERE['stock.group_id']     = 'stock.group_id   = '.CURRENT_GROUP_ID.'';
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
            '.$WHERE.'
            GROUP BY "using".purpose_id, stock.reagent_id
            ORDER BY  consume_quantity DESC
            ;
        '.QUERY_CACHABLE;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            if( !isset($data[$row['purpose_id']]) ){ $data[$row['purpose_id']] = array(); }
            if( !isset($data[$row['purpose_id']][$row['reagent_id']]) ){ $data[$row['purpose_id']][$row['reagent_id']] = array(); }

            $data[$row['purpose_id']][$row['reagent_id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }

    //////////////////////


    public final function get_stats_consume_dynamics_html( $filters = array() )
    {
        $data = $this->get_stats_consume_dynamics_raw( $filters );

        if( !is_array($data) || !count($data) ){ return false; }

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();

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

    public final function get_stats_consume_dynamics_raw( $filters = array() )
    {
        $WHERE = array();
        $WHERE['consume.date']       = 'consume.date     > \'1970-01-01\'::date';
        $WHERE['stock.id']           = 'stock.id         > \'0\'::integer';
        $WHERE['stock.group_id']     = 'stock.group_id   = '.CURRENT_GROUP_ID.'';
        $WHERE['stock.reagent_id']   = 'stock.reagent_id > 0';

        $filters = is_array($filters) ? $filters : array();
        $filters['year_correction'] = common::integer( isset($filters['year_correction']) ? $filters['year_correction'] : 0 );

        $WHERE['consume.date:year_from']    = 'consume.date >= date_trunc( \'year\', NOW() '.($filters['year_correction']>=0?'+':'-').' INTERVAL \''. ( abs($filters['year_correction']) ) .' year\' )';
        $WHERE['consume.date:year_to']      = 'consume.date < date_trunc( \'year\', NOW() '. ( ($filters['year_correction']>=0?'+':'-').' INTERVAL \''. ( abs( 1 + $filters['year_correction'] ) ) .' year\' '  ) .')';


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
            '.$WHERE.'
            GROUP BY stock.reagent_id
            ;
        '.QUERY_CACHABLE;

        // echo $SQL;exit;

        $cache_var = 'stats-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['reagent_id']] = $row;
        }

        cache::set( $cache_var, $data );

        return $data;
    }

}
















