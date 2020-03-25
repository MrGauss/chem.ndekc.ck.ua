<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class cooked
{
    use basic, spr, db_connect;

    public final function save( $reactiv_hash = false, $data = array() )
    {
        if( !is_array($data) )            { common::err( 'Помилка передачі даних!' ); }
        if( !isset($data['composition']) || !is_array($data['composition']) || !count(($data['composition'])) ){ common::err( 'Відсутня інформація про компоненти!' ); }

        /////////
        $purpose = array();
        foreach( ( ( new spr_manager( 'purpose' )   )->get_raw() ) as $purpose_elem )
        {
            if( $purpose_elem['attr'] == 'reactiv' )
            {
                $purpose = $purpose_elem;
                $purpose_elem = null;
                unset( $purpose_elem );
                break;
            }
        }
        /////////

        $SQL = array();
        $SQL['reactiv'] = array();

        $SQL['reactiv']['reactiv_menu_id'] = common::integer( isset($data['reactiv_menu_id']) ? $data['reactiv_menu_id'] : false );
        $SQL['reactiv']['quantity_inc']    = common::float( isset($data['quantity_inc']) ? $data['quantity_inc'] : false );
        $SQL['reactiv']['inc_expert_id']   = common::integer( isset($data['inc_expert_id']) ? $data['inc_expert_id'] : false );
        $SQL['reactiv']['group_id']        = CURRENT_GROUP_ID;
        $SQL['reactiv']['inc_date']        = date( 'Y-m-d', common::integer( isset($data['inc_date']) ? strtotime($data['inc_date']) : 0 ) );
        $SQL['reactiv']['dead_date']       = date( 'Y-m-d', common::integer( isset($data['dead_date']) ? strtotime($data['dead_date']) : 0 ) );
        $SQL['reactiv']['using_hash']      = common::filter_hash( isset($data['using_hash']) ? $data['using_hash'] : '%USING_HASH%' );
        $SQL['reactiv']['safe_place']      = common::filter( isset($data['safe_place']) ? $data['safe_place'] : false );
        $SQL['reactiv']['safe_needs']      = common::filter( isset($data['safe_needs']) ? $data['safe_needs'] : false );
        $SQL['reactiv']['comment']         = common::filter( isset($data['comment']) ? $data['comment'] : false );

        //////

        $SQL['using'] = array();
        $SQL['using']['date']       = $SQL['reactiv']['inc_date'];
        $SQL['using']['purpose_id'] = $purpose['id'];

        if( strlen($SQL['reactiv']['using_hash']) != 32 )
        {
            $SQL['reactiv']['using_hash'] = false;
            $SQL['using'] = array_map( array( $this->db, 'safesql' ), $SQL['using'] );
            $SQL['using'] = 'INSERT INTO "using" ("'. implode( '", "', array_keys($SQL['using']) ) .'") VALUES (\''. implode( '\', \'', array_values($SQL['using']) ) .'\') RETURNING "hash";';
        }
        else
        {
            $SQL['using'] = array_map( array( $this->db, 'safesql' ), $SQL['using'] );
            foreach( $SQL['using'] as $k => $v ){ $SQL['using'][$k] = '"'.$k.'" = \''.$v.'\' '; }
            $SQL['using'] = 'UPDATE "using" SET '.implode( ', ', $SQL['using'] ).' WHERE "hash" = \''.$SQL['reactiv']['using_hash'].'\' RETURNING "hash";';
        }

        //////

        $SQL['consume'] = array();
        foreach( $data['composition'] as $ingridient )
        {
            $ingridient['consume_hash'] = common::filter( isset( $ingridient['consume_hash'] ) ? $ingridient['consume_hash'] : false );
            // $ingridient['consume_hash']
            $SQL['consume'][$ingridient['dispersion_id']]['dispersion_id'] = common::integer( $ingridient['dispersion_id'] );
            $SQL['consume'][$ingridient['dispersion_id']]['inc_expert_id'] = common::integer( $SQL['reactiv']['inc_expert_id'] );
            $SQL['consume'][$ingridient['dispersion_id']]['quantity']      = common::float( $ingridient['quantity'] );
            $SQL['consume'][$ingridient['dispersion_id']]['using_hash']    = $SQL['reactiv']['using_hash'] ? $SQL['reactiv']['using_hash'] : '%USING_HASH%';

            if( strlen($ingridient['consume_hash']) == 32 )
            {

                $SQL['consume'][$ingridient['dispersion_id']] = array_map( array( $this->db, 'safesql' ), $SQL['consume'][$ingridient['dispersion_id']] );
                foreach( $SQL['consume'][$ingridient['dispersion_id']] as $k => $v ){ $SQL['consume'][$ingridient['dispersion_id']][$k] = '"'.$k.'" = \''.$v.'\' '; }
                $SQL['consume'][$ingridient['dispersion_id']] = 'UPDATE "consume" SET '.implode( ', ', $SQL['consume'][$ingridient['dispersion_id']] ).' WHERE "hash" = \''.$ingridient['consume_hash'].'\' RETURNING "hash";';
            }
            else
            {
                $SQL['consume'][$ingridient['dispersion_id']] = array_map( array( $this->db, 'safesql' ), $SQL['consume'][$ingridient['dispersion_id']] );
                $SQL['consume'][$ingridient['dispersion_id']] = 'INSERT INTO "consume" ("'. implode( '", "', array_keys($SQL['consume'][$ingridient['dispersion_id']]) ) .'") VALUES (\''. implode( '\', \'', array_values($SQL['consume'][$ingridient['dispersion_id']]) ) .'\') RETURNING "hash";';
            }
        }

        if( strlen($reactiv_hash) == 32 )
        {
            $SQL['reactiv'] = array_map( array( $this->db, 'safesql' ), $SQL['reactiv'] );
            foreach( $SQL['reactiv'] as $k => $v ){ $SQL['reactiv'][$k] = '"'.$k.'" = \''.$v.'\' '; }
            $SQL['reactiv'] = 'UPDATE "reactiv" SET '.implode( ', ', $SQL['reactiv'] ).' WHERE "hash" = \''.$reactiv_hash.'\' RETURNING "hash";';
        }
        else
        {
            $SQL['reactiv']['using_hash'] = false;
            $SQL['reactiv'] = array_map( array( $this->db, 'safesql' ), $SQL['reactiv'] );
            $SQL['reactiv'] = 'INSERT INTO "reactiv" ("'. implode( '", "', array_keys($SQL['reactiv']) ) .'") VALUES (\''. implode( '\', \'', array_values($SQL['reactiv']) ) .'\') RETURNING "hash";';
        }




        var_export($SQL); echo "\n";
        // var_export($data);
        exit;
    }


    public final function editor( $line_hash = false, $skin = false )
    {
        $line_hash = common::filter_hash( $line_hash );

        $data = $this->get_raw( array( 'hash' => $line_hash ) );
        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : false;

        if( !is_array($data) ){ return false; }

        $tpl = new tpl;

        $tpl->load( $skin );

        $_dates = array();
        $_dates[] = 'inc_date';
        $_dates[] = 'dead_date';

        foreach( $_dates as $_date )
        {
            $data[$_date]       = isset($data[$_date])      ? common::en_date( $data[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
            if( strpos( $data[$_date], '.197' ) !== false ){ $data[$_date] = ''; }
        }

        $data['key'] = common::key_gen( $line_hash );

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            $tpl->set( '{autocomplete:'.$k.':key}', autocomplete::key( 'reactiv', $k ) );
        }

        /////////////
        $dispersion = new dispersion;
        $tpl->set( '{ingridients}', $dispersion->get_html( array(  ), 'cooked/ingridient' ) );
        /////////////
        $tpl->set( '{composition}', $this->get_html_composition( $data['composition'], 'cooked/composition' ) );
        /////////////

        $tpl->set( '{autocomplete:table}', 'reactiv' );
        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_html_composition( $data = array(), $skin = false )
    {
        $data = is_array($data) ? $data : array();

        $_dates = array();
        $_dates[] = 'consume_ts';
        $_dates[] = 'consume_date';
        $_dates[] = 'using_date';
        $_dates[] = 'dispersion_inc_date';

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();


        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );

            $tags = array();

            foreach( $_dates as $_date )
            {
                $line[$_date]       = isset($line[$_date])      ? common::en_date( $line[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
                if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
            }

            $line['numi'] = $I--;

            $line = common::db2html( $line );

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }

                $tags[] = '{tag:'.$key.'}';

                $tpl->set( '{tag:'.$key.'}', common::db2html( $value ) );
            }

            foreach( isset($reagent[$line['reagent_id']]) ? $reagent[$line['reagent_id']] : array() as $key => $value )
            {
                if( is_array($value) ){ continue; }

                $tags[] = '{tag:reagent:'.$key.'}';

                $tpl->set( '{tag:reagent:'.$key.'}', common::db2html( $value ) );
            }

            if( isset($reagent[$line['reagent_id']]) && isset($reagent[$line['reagent_id']]['units_id']) && $reagent[$line['reagent_id']]['units_id'] )
            {
                foreach( isset($units[$reagent[$line['reagent_id']]['units_id']]) ? $units[$reagent[$line['reagent_id']]['units_id']] : array() as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:reagent:units:'.$key.'}';

                    $tpl->set( '{tag:reagent:units:'.$key.'}', common::db2html( $value ) );
                }
            }

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        $_dates = array();
        $_dates[] = 'inc_date';
        $_dates[] = 'dead_date';

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );

            foreach( $_dates as $_date )
            {
                $line[$_date]       = isset($line[$_date])      ? common::en_date( $line[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
                if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
            }

            $line['numi'] = $I--;

            $line = common::db2html( $line );

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tpl->set( '{tag:'.$key.'}', $value );
            }

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
        if( is_array($filters) )
        {
            if( isset($filters['hash']) ){ $filters['hash'] = common::filter_hash( $filters['hash'] ); }
        }

        $SQL = '
            SELECT
                reactiv.*,
                "using".hash as using_hash,
                reactiv_menu.name       as reactiv_name,
                reactiv_menu.units_id   as reactiv_units_id,
                reactiv_menu."comment"  as reactiv_comment,
                "using".purpose_id
            FROM
                reactiv
                    LEFT JOIN reactiv_menu ON ( reactiv_menu.id = reactiv.reactiv_menu_id )
                    LEFT JOIN "using" ON ( "using".hash = reactiv.using_hash )
            WHERE
                '.(( isset($filters['hash']) ) ? 'reactiv.hash = \''.$filters['hash'].'\'' : 'reactiv.hash != \'\'').'
                '.(( isset($filters['hash']) && $filters['hash'] == '' ) ? ''    :(CURRENT_GROUP_ID?'AND reactiv.group_id = '.CURRENT_GROUP_ID.'':'')).'
            ORDER by
                reactiv_name ASC; '.db::CACHED;

        $cache_var = 'spr-reactiv-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        //if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['hash']] = $row;
            $data[$row['hash']]['composition'] = array();
        }

        //////////////////////////////////////////////////////////////////////////////////
        if( is_array($data) && count($data) )
        {
            $consume = new consume;

            foreach( $consume->get_raw( array( 'reactiv_hash' => array_keys( $data ) ) ) as $consume_hash => $consume_data )
            {
                if( !isset($data[$consume_data['reactiv_hash']]) || !isset($data[$consume_data['reactiv_hash']]['composition']) )
                {
                    common::err( 'Помилка отримання даних з бази даних!' );
                }

                $reactiv = &$data[$consume_data['reactiv_hash']];

                if( $reactiv['using_hash'] != $consume_data['using_hash'] )
                {
                    common::err( 'Витарта реактивів має різні призначення! Хуйня якась!' );
                }

                $reactiv['composition'][$consume_hash] = $consume_data;
            }
        }
        //////////////////////////////////////////////////////////////////////////////////

        cache::set( $cache_var, $data );
        return $data;
    }

}