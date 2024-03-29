<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class using
{
    use basic, spr, db_connect;

    public final function update_reactiv_consume_using( $using_hash = false, $consume_hash = array() )
    {
        $using_hash = common::filter_hash( $using_hash );

        if( !$using_hash ){ return false; }

        $using_hash = $this->db->safesql($using_hash);

        $this->db->query( 'DELETE FROM reactiv_consume_using WHERE using_hash=\''.$using_hash.'\';' );

        if( !is_array($consume_hash) ){ return false; }

        $ins = array();
        foreach( $consume_hash as $hash )
        {
            $hash = common::filter_hash( $hash );
            if( $hash ){ $ins[] = '( \''. $using_hash .'\', \''. $hash .'\' )'; }
        }

        if( count($ins) )
        {
            $ins = 'INSERT INTO reactiv_consume_using ( using_hash, consume_hash ) VALUES '.implode( ', ', $ins ).';';
            $this->db->query( $ins );
        }

        return true;
    }

    public final static function filters( $data )
    {
        $FILTERS = array();

        $FILTERS['reagent_id']          = common::integer( isset( $data['reagent_id'] ) ? $data['reagent_id'] : 0 );
        $FILTERS['purpose_id']          = common::integer( isset( $data['purpose_id'] ) ? $data['purpose_id'] : 0 );
        $FILTERS['expert_id']           = common::integer( isset( $data['expert_id'] ) ? $data['expert_id'] : 0 );
        $FILTERS['using_date'] = array();
        $FILTERS['using_date']['from']     = common::trim( isset( $data['using_date_from'] ) ? date('d.m.Y',  strtotime($data['using_date_from'] )) : '01.'.date('m.Y')   );
        $FILTERS['using_date']['to']       = common::trim( isset( $data['using_date_to'] ) ? date('d.m.Y',    strtotime($data['using_date_to']   )) :       date('d.m.Y') );

        return $FILTERS;
    }

    public final function update_consume_using( $using_hash = false, $consume_hash = array() )
    {
        $using_hash = common::filter_hash( $using_hash );

        if( !$using_hash ){ return false; }

        $using_hash = $this->db->safesql($using_hash);

        $this->db->query( 'DELETE FROM consume_using WHERE using_hash=\''.$using_hash.'\';' );

        if( !is_array($consume_hash) ){ return false; }

        $ins = array();
        foreach( $consume_hash as $hash )
        {
            $hash = common::filter_hash( $hash );
            if( $hash ){ $ins[] = '( \''. $using_hash .'\', \''. $hash .'\' )'; }
        }

        if( count($ins) )
        {
            $ins = 'INSERT INTO consume_using ( using_hash, consume_hash ) VALUES '.implode( ', ', $ins ).';';
            $this->db->query( $ins );
        }

        return true;
    }

    public final function simple_save_using( $data = array() )
    {
        $data4db =
            array (
                'purpose_id' => common::integer( isset($data['purpose_id']) ? $data['purpose_id'] : false ),
                'group_id' => CURRENT_GROUP_ID,
                'date' => isset($data['date'])? common::en_date( $data['date'], 'Y-m-d' ) . ' ' . date( 'H:i:s' ) : false,
            );

        foreach( $data4db as $k => $v )
        {
            if( !$v )
            {
                return self::error( 'using hash error!' );
            }
        }

        $hash = isset($data['hash']) ? common::filter_hash( $data['hash'] ) : false;

        if( !$hash )
        {
            $query = 'INSERT INTO "using" '.db::array2ins( $data4db ).' RETURNING hash;';
        }
        else
        {
            $query = 'UPDATE "using" SET '.db::array2upd( $data4db ).' WHERE hash=\''.$this->db->safesql( $data['hash'] ).'\' RETURNING hash;';
        }

        $hash = $this->db->super_query( $query );
        if( is_array($hash) && isset($hash['hash']) ){ $hash = $hash['hash']; }
        else{ $hash = false; }

        return $hash;
    }

    public final function get_raw( $filters = array() )
    {
        $filters = is_array($filters) ? $filters : array();
        $WHERE = array();

        $WHERE['group_id']   = '( "using".group_id = '.CURRENT_GROUP_ID.' OR "using".group_id = 0 )';

        /////////////////////
        if( isset($filters['reactiv_hash']) )
        {
            $filters['reactiv_hash'] = common::filter_hash( $filters['reactiv_hash'] );
            if( !is_array($filters['reactiv_hash']) ){ $filters['reactiv_hash'] = array( $filters['reactiv_hash'] ); }

            $filters['reactiv_hash'] = array_unique($filters['reactiv_hash']);

            if( count($filters['reactiv_hash']) )
            {
                $filters['reactiv_hash'] = array_map( array( $this->db, 'safesql' ), $filters['reactiv_hash'] );
                $WHERE['reactiv_hash']   = 'reactiv.hash IN(\''. implode( '\', \'', array_values( $filters['reactiv_hash'] ) ) .'\')';
            }
        }
        /////////////////////

        if( isset($filters['using_date']) )
        {
            if( !is_array($filters['using_date']) )
            {
                $filters['using_date'] = array( 'from' => $filters['using_date'], 'to' => $filters['using_date'] );
            }

            if( isset($filters['using_date']['from']) ){ $filters['using_date']['from'] = date( 'Y-m-d', strtotime( $filters['using_date']['from'] ) );  }
            if( isset($filters['using_date']['to']) ){ $filters['using_date']['to'] = date( 'Y-m-d', strtotime( $filters['using_date']['to'] ) );  }

            if( isset($filters['using_date']['from']) && isset($filters['using_date']['to']) )
            {
                $WHERE['using_date'] = '( "using"."date"::date >= \''.$filters['using_date']['from'].'\'::date AND "using"."date"::date <= \''.$filters['using_date']['to'].'\'::date ) ';
            }
        }

        /////////////////////
        if( isset($filters['reactiv_menu_id']) )
        {
            $filters['reactiv_menu_id']  = common::integer( $filters['reactiv_menu_id'] );
            if( !is_array($filters['reactiv_menu_id']) ){ $filters['reactiv_menu_id'] = array( $filters['reactiv_menu_id'] ); }

            $filters['reactiv_menu_id'] = array_unique($filters['reactiv_menu_id']);
            sort( $filters['reactiv_menu_id'] );

            if( count($filters['reactiv_menu_id']) )
            {
                $filters['reactiv_menu_id'] = array_map( array( $this->db, 'safesql' ), $filters['reactiv_menu_id'] );
                $WHERE['reactiv_menu_id']   = 'reactiv.reactiv_menu_id IN(\''. implode( '\', \'', array_values( $filters['reactiv_menu_id'] ) ) .'\')';
            }
        }
        /////////////////////

        //var_export( $WHERE );exit;

        /////////////////////
        if( isset($filters['reagent_id']) )
        {
            $filters['reagent_id']  = common::integer( $filters['reagent_id'] );
            if( !is_array($filters['reagent_id']) ){ $filters['reagent_id'] = array( $filters['reagent_id'] ); }

            $filters['reagent_id'] = array_unique($filters['reagent_id']);
            sort( $filters['reagent_id'] );

            while( is_array($filters['reagent_id']) && count($filters['reagent_id']) && isset($filters['reagent_id'][0]) && $filters['reagent_id'][0] == 0 )
            {
                unset( $filters['reagent_id'][0] );
                sort( $filters['reagent_id'] );
            }

            if( count($filters['reagent_id']) )
            {
                $filters['reagent_id'] = array_map( array( $this->db, 'safesql' ), $filters['reagent_id'] );
                $WHERE['reagent_id']   = 'stock.reagent_id IN('. implode( ', ', array_values( $filters['reagent_id'] ) ) .')';
            }
        }
        /////////////////////

        /////////////////////
        if( isset($filters['purpose_id']) )
        {
            $filters['purpose_id']  = common::integer( $filters['purpose_id'] );
            if( !is_array($filters['purpose_id']) ){ $filters['purpose_id'] = array( $filters['purpose_id'] ); }

            $filters['purpose_id'] = array_unique($filters['purpose_id']);
            sort( $filters['purpose_id'] );

            while( is_array($filters['purpose_id']) && count($filters['purpose_id']) && isset($filters['purpose_id'][0]) && $filters['purpose_id'][0] == 0 )
            {
                unset( $filters['purpose_id'][0] );
                sort( $filters['purpose_id'] );
            }

            if( count($filters['purpose_id']) )
            {
                $filters['purpose_id'] = array_map( array( $this->db, 'safesql' ), $filters['purpose_id'] );
                $WHERE['purpose_id']   = '"using".purpose_id IN('. implode( ', ', array_values( $filters['purpose_id'] ) ) .')';
            }
        }
        /////////////////////

        /////////////////////
        if( isset($filters['expert_id']) )
        {
            $filters['expert_id']  = common::integer( $filters['expert_id'] );
            if( !is_array($filters['expert_id']) ){ $filters['expert_id'] = array( $filters['expert_id'] ); }

            $filters['expert_id'] = array_unique($filters['expert_id']);
            sort( $filters['expert_id'] );

            while( is_array($filters['expert_id']) && count($filters['expert_id']) && isset($filters['expert_id'][0]) && $filters['expert_id'][0] == 0 )
            {
                unset( $filters['expert_id'][0] );
                sort( $filters['expert_id'] );
            }

            if( count($filters['expert_id']) )
            {
                $filters['expert_id'] = array_map( array( $this->db, 'safesql' ), $filters['expert_id'] );
                $WHERE['expert_id']   = '"using".expert_id IN('. implode( ', ', array_values( $filters['expert_id'] ) ) .')';
            }
        }
        /////////////////////

        /////////////////////
        if( isset($filters['hash']) )
        {
            $filters['hash'] = common::filter_hash( $filters['hash'] );
            if( !is_array($filters['hash']) ){ $filters['hash'] = array( $filters['hash'] ); }

            $filters['hash'] = array_unique($filters['hash']);

            if( count($filters['hash']) )
            {
                $filters['hash'] = array_map( array( $this->db, 'safesql' ), $filters['hash'] );
                $WHERE['hash']   = '"using".hash IN(\''. implode( '\', \'', array_values( $filters['hash'] ) ) .'\')';

                $WHERE['reactiv_hash']      = null; unset( $WHERE['reactiv_hash'] );
                $WHERE['reactiv_menu_id']   = null; unset( $WHERE['reactiv_menu_id'] );
            }
        }
        else
        {
            $WHERE['hash']       = '"using".hash != \'\'';
        }
        /////////////////////


        /////////////////////

        $WHERE = count($WHERE) ? 'WHERE '."\n\t\t\t\t".implode( "\n\t\t\t\t".'AND'."\n\t\t\t\t", $WHERE ) : '';

        /////////////////////

        $SQL = '
            SELECT
                    "using".hash,
                    coalesce(string_agg( distinct consume.hash::text, \',\' ),\'\') as consume_hash_agg,
                    coalesce(string_agg( distinct reactiv_consume.hash::text, \',\' ),\'\') as reactiv_consume_hash_agg,
                    coalesce(string_agg( distinct reactiv.hash, \',\' ),\'\') as reactiv_hash_agg,
                    "using".date,
                    "using".purpose_id,
                    "using".group_id,
                    "using".exp_number,
                    "using".exp_date,
                    "using".expert_id,
                    "using".obj_count,
                    "using".tech_info,
                    "using".ucomment
            FROM
                    "using"
                        LEFT JOIN consume_using ON( consume_using.using_hash = "using".hash )
                            LEFT JOIN consume ON( consume.hash = consume_using.consume_hash )
                                LEFT JOIN dispersion ON( dispersion.id = consume.dispersion_id )
                                    LEFT JOIN stock ON( stock.id = dispersion.stock_id )

                        LEFT JOIN reactiv_consume_using ON( reactiv_consume_using.using_hash = "using".hash )
                            LEFT JOIN reactiv_consume ON( reactiv_consume.hash = reactiv_consume_using.consume_hash )

                        LEFT JOIN reactiv_ingr_reactiv ON( reactiv_ingr_reactiv.consume_hash = reactiv_consume.hash )
                        LEFT JOIN reactiv_ingr_reagent ON( reactiv_ingr_reagent.consume_hash = consume.hash )
                        LEFT JOIN reactiv ON( reactiv.hash = reactiv_ingr_reactiv.reactiv_hash OR reactiv.hash = reactiv_ingr_reagent.reactiv_hash )
            '.$WHERE.'
            GROUP BY "using".hash
            ORDER BY "using".date DESC;
            ';

        //echo $SQL;exit;

        $cache_var = 'using-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }

        $data = array();
        $SQL = $this->db->query( $SQL );
        $reactives = array();

        $addict_data = array();

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['hash']                    = common::filter_hash( $row['hash'] ? $row['hash'] : '' );
            $row['reactiv_hash']            = common::filter_hash( explode( ',', $row['reactiv_hash_agg']         ));
            $row['consume_hash']            = common::filter_hash( explode( ',', $row['consume_hash_agg']         ));
            $row['reactiv_consume_hash']    = common::filter_hash( explode( ',', $row['reactiv_consume_hash_agg'] ));

            foreach
            (
                array
                (
                    'reactiv_hash',
                    'consume_hash',
                    'reactiv_consume_hash',
                )
                as $k
            )
            {
                if( !is_array($row[$k]) ){ $row[$k] = array( $row[$k] ); }

                $b = array();
                foreach( $row[$k] as $key => $value )
                {
                    if( $value )
                    {
                        $b[$value] = array();

                        if( !isset($addict_data[$k]) ){ $addict_data[$k] = array(); }
                        $addict_data[$k][] = $value;
                    }
                }
                $row[$k] = $b;
            }

            $data[$row['hash']] = $row;
            $data[$row['hash']]['ucomment']           = common::decode_string( common::stripslashes( $data[$row['hash']]['ucomment'] ) );
        }

        if( isset($addict_data['consume_hash']) && is_array($addict_data['consume_hash']) && count($addict_data['consume_hash']) )
        {
            foreach( ( new consume )->get_raw( array( 'consume_hash' => $addict_data['consume_hash'] ) ) as $line )
            {
                $data[$line['using_hash']]['consume_hash'][$line['consume_hash']] = $line;
            }
        }

        if( isset($addict_data['reactiv_consume_hash']) && is_array($addict_data['reactiv_consume_hash']) && count($addict_data['reactiv_consume_hash']) )
        {
            foreach( ( new reactiv_consume )->get_raw( array( 'consume_hash' => $addict_data['reactiv_consume_hash'] ) ) as $line )
            {
                $data[$line['using_hash']]['reactiv_consume_hash'][$line['consume_hash']] = $line;
            }
        }

        if( isset($addict_data['reactiv_hash']) && is_array($addict_data['reactiv_hash']) && count($addict_data['reactiv_hash']) )
        {
            foreach( ( new cooked )->get_raw( array( 'hash' => $addict_data['reactiv_hash'] ) ) as $line )
            {
                $data[$line['using_hash']]['reactiv_hash'][$line['hash']] = $line;
            }
        }

        cache::set( $cache_var, $data );
        return $data;
    }

    public final function editor( $line_hash = '', $skin = false )
    {
        access::check( 'using', 'view' );

        //////////
        $reagent = ( new spr_manager( 'reagent' ) ) ->get_raw();
        $units   = ( new spr_manager( 'units' ) ) ->get_raw();
        $recipes = ( new recipes() )                ->get_raw();
        //////////

        $_skin = array
        (
            'consume'         => 'using/consume_line',
            'reactiv_consume' => 'using/reactiv_consume_line',
        );

        $line_hash = common::filter_hash( $line_hash );

        $data = $this->get_raw( array( 'hash' => $line_hash ) );
        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : array();

        if( !is_array($data) ){ return false; }

        $_dates = array();
        $_dates[] = 'date';
        $_dates[] = 'exp_date';

        foreach( $_dates as $_date )
        {
            $data[$_date]       = isset($data[$_date])      ? common::en_date( $data[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
            if( strpos( $data[$_date], '.197' ) !== false ){ $data[$_date] = ''; }
        }

        $tpl = new tpl;

        $data['hash'] = common::trim( isset($data['hash'])?$data['hash']:'' );
        $data['key'] = common::key_gen( $line_hash );

        $data['purpose_id'] = common::integer( ( isset($data['purpose_id']) && $data['purpose_id'] ) ? $data['purpose_id'] : 1 );
        $data['obj_count']  = common::integer( ( isset($data['obj_count']) && $data['obj_count'] )   ? $data['obj_count'] : 0 );
        $data['exp_number'] = common::filter ( ( isset($data['exp_number']) && $data['exp_number'] )   ? $data['exp_number'] : '' );
        $data['ucomment']   = common::filter ( ( isset($data['ucomment']) && $data['ucomment'] )   ? $data['ucomment'] : '' );
        $data['tech_info']  = common::filter ( ( isset($data['tech_info']) && $data['tech_info'] )   ? $data['tech_info'] : '' );

        // consume_hash
        $data['consume_hash'] = ( isset($data['consume_hash']) && is_array($data['consume_hash']) )?$data['consume_hash']:array();
        $data['reactiv_consume_hash'] = ( isset($data['reactiv_consume_hash']) && is_array($data['reactiv_consume_hash']) )?$data['reactiv_consume_hash']:array();


        foreach( array_merge( $data['consume_hash'], $data['reactiv_consume_hash'] ) as $consume_hash => $consume_data )
        {
            if( isset($consume_data['dispersion_id']) )
            {
                $_consume_skin = $_skin['consume'];
            }
            else
            {
                $_consume_skin = $_skin['reactiv_consume'];
            }

            $consume_data['key'] = common::key_gen( $consume_data['consume_hash'] . $consume_data['using_hash'] . $consume_data['reactiv_hash'] );

            $tpl->load( $_consume_skin );

            if( isset( $consume_data['dispersion_quantity_left'] ) ){ $consume_data['dispersion_quantity_left'] = $consume_data['dispersion_quantity_left'] + $consume_data['quantity']; }
            if( isset( $consume_data['reactiv_quantity_left'] ) ){ $consume_data['reactiv_quantity_left'] = $consume_data['reactiv_quantity_left'] + $consume_data['quantity']; }

            foreach( $consume_data as $k => $v )
            {
                if( is_array($v) ){ continue; }
                $tpl->set( '{consume:'.$k.'}', common::db2html( $v ) );
            }

            if( isset( $consume_data['reactiv_menu_id'] ) && isset( $recipes[$consume_data['reactiv_menu_id']] ) )
            {
                foreach( $recipes[$consume_data['reactiv_menu_id']] as $k => $v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{consume:recipe:'.$k.'}', common::db2html( $v ) );
                }

                foreach( $units[$recipes[$consume_data['reactiv_menu_id']]['units_id']] as $k => $v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{consume:units:'.$k.'}', common::db2html( $v ) );
                }
            }

            if( isset( $consume_data['reagent_id'] ) && isset( $reagent[$consume_data['reagent_id']] ) )
            {
                foreach( $reagent[$consume_data['reagent_id']] as $k => $v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{consume:reagent:'.$k.'}', common::db2html( $v ) );
                }

                foreach( $units[$reagent[$consume_data['reagent_id']]['units_id']] as $k => $v )
                {
                    if( is_array($v) ){ continue; }
                    $tpl->set( '{consume:units:'.$k.'}', common::db2html( $v ) );
                }
            }

            $tpl->compile( $_consume_skin );
        }

        $tpl->load( $skin );
        $tags = array();

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tags[] = '{tag:'.$k.'}';

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            $tpl->set( '{autocomplete:'.$k.':key}', autocomplete::key( 'stock', $k ) );
        }

        foreach( ( isset($data['reactiv_hash']) && is_array($data['reactiv_hash']) )?$data['reactiv_hash']:array() as $reactiv_hash => $reactiv_data )
        {
            foreach( $reactiv_data as $k => $v )
            {
                if( is_array( $v ) ){ continue; }
                $tags[] = '{tag:reactiv:'.$k.'}';
                $tpl->set( '{tag:reactiv:'.$k.'}', common::db2html( $v ) );
            }

            if( isset($reactiv_data['units_id']) && isset($units[$reactiv_data['units_id']]) )
            {
                foreach( $units[$reactiv_data['units_id']] as $k => $v )
                {
                    if( is_array( $v ) ){ continue; }
                    $tags[] = '{tag:reactiv:units:'.$k.'}';
                    $tpl->set( '{tag:reactiv:units:'.$k.'}', common::db2html( $v ) );
                }
            }
        }

        $tpl->set( '{cooked:list}',      ( new cooked )     ->get_html( array( 'quantity_left:more' => 0 ), 'using/selectable_element_cooked' ) );
        $tpl->set( '{dispersion:list}',  ( new dispersion ) ->get_html( array( 'quantity_left:more' => 0 ), 'using/selectable_element_dispersion' ) );

        $tpl->set( '{consume:list}',            $tpl->result( $_skin['consume'] ) );
        $tpl->set( '{reactiv_consume:list}',    $tpl->result( $_skin['reactiv_consume'] ) );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $_dates = array();
        $_dates[] = 'date';
        $_dates[] = 'exp_date';

        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        if( !count($data) ){ return false; }

        $purpose = ( new spr_manager( 'purpose' ) ) ->get_raw();
        $reagent = ( new spr_manager( 'reagent' ) ) ->get_raw();
        $units   = ( new spr_manager( 'units'   ) ) ->get_raw();
        $recipes = ( new recipes() )                ->get_raw();
        $users   = ( new user )                      ->get_raw( array( 'expert.group_id' => CURRENT_GROUP_ID ) );

        $tpl = new tpl;

        $I = count( $data );
        $J = 0;
        foreach( $data as $line )
        {

            $tpl->load( $skin );

            $line['numi'] = $I--;
            $line['numa'] = ++$J;
            $line['numb'] = ($line['numa'] & 1) ? 'odd' : 'even';


            $line['hash_segm'] = preg_replace( '!(\w{8})!i', '$1 ', $line['hash'] );

            $tags = array();

            if( isset($line['inc_expert_id']) && isset($users[$line['inc_expert_id']]) )
            {
                foreach( $users[$line['inc_expert_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }
                    $tags[] = '{tag:user:'.$key.'} : \''.common::db2html( $value ).'\'';
                    $tpl->set( '{tag:user:'.$key.'}', common::db2html( $value ) );
                }

                $tpl->set( '{tag:user:name:1}',     common::db2html( substr( $users[$line['inc_expert_id']]['name']     , 0, 1 ) ) );
                $tpl->set( '{tag:user:surname:1}',  common::db2html( substr( $users[$line['inc_expert_id']]['surname']  , 0, 1 ) ) );
                $tpl->set( '{tag:user:phname:1}',   common::db2html( substr( $users[$line['inc_expert_id']]['phname']   , 0, 1 ) ) );
            }


            foreach( $_dates as $_date )
            {
                if( !isset($line[$_date]) ){ continue; }
                $line[$_date.'_unix'] = strtotime($line[$_date]);
                $line[$_date] = common::en_date( $line[$_date], 'd.m.Y' );
                if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
            }

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tags[] = '{tag:using:'.$key.'} : \''.common::db2html( $value ).'\'';
                $tpl->set( '{tag:using:'.$key.'}', common::db2html( $value ) );
            }


            foreach( isset($purpose[$line['purpose_id']])?$purpose[$line['purpose_id']]:array() as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tags[] = '{tag:purpose:'.$key.'} : \''.common::db2html( $value ).'\'';
                $tpl->set( '{tag:purpose:'.$key.'}', common::db2html( $value ) );
            }

            $tpl->set_block( '!\[purpose:('.$line['purpose_id'].')\](.+?|)\[\/purpose\]!is', '$2' );
            $tpl->set_block( '!\[purpose:(\d+?)\](.+?|)\[\/purpose\]!is', '' );


            // ���� �������� ������� /////////////////////////////////////////////////////
            if( isset($line['reactiv_hash']) )
            {
                foreach( $line['reactiv_hash'] as $reactive )
                {
                    //var_export( $reactive['units_id'] );exit;

                    $tpl->set( '[reactive]', '' );
                    $tpl->set( '[/reactive]', '' );

                    foreach( $reactive as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:reactive:'.$key.'} : \''.common::db2html( $value ).'\'';
                        $tpl->set( '{tag:reactive:'.$key.'}', common::db2html( $value ) );
                    }

                    /*
                    foreach( isset($recipes[$reactive['reactiv_menu_id']])?$recipes[$reactive['reactiv_menu_id']]:array() as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:recipe:'.$key.'} : \''.common::db2html( $value ).'\'';
                        $tpl->set( '{tag:recipe:'.$key.'}', common::db2html( $value ) );
                    }
                    */

                    foreach( isset($units[$reactive['units_id']])?$units[$reactive['units_id']]:array() as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:units:'.$key.'} : \''.common::db2html( $value ).'\'';
                        $tpl->set( '{tag:units:'.$key.'}', common::db2html( $value ) );
                    }
                }
            }
            $tpl->set_block( '!\[reactive\](.+?)\[\/reactive\]!is', '' );
            //////////////////////////////////////////////////////////////////////////////

            $ingridients = array();

            $consume_user_id = 0;
            foreach( $line['consume_hash'] as $consume )
            {
                if( !$consume_user_id )
                {
                    $consume_user_id = common::integer( $consume['inc_expert_id'] );
                }
                else
                {
                    if( $consume_user_id != $consume['inc_expert_id'] )
                    {
                        // FUCK &
                    }
                }

                $ingridients[] = '
                    <div class="consume_elem">
                        <span class="reagent_name">'.common::db2html($reagent[$consume['reagent_id']]['name']).'</span>
                        <span class="reagent_number">['.common::db2html($consume['reagent_number']).']</span>
                        <span class="quantity">'.common::db2html($consume['quantity']).'</span>
                        <span class="units_short_name">'.common::db2html($units[$reagent[$consume['reagent_id']]['units_id']]['short_name']).'</span>
                    </div>
                ';
            }

            foreach( $line['reactiv_consume_hash'] as $consume )
            {
                // var_export($consume); exit;

                if( !$consume_user_id )
                {
                    $consume_user_id = common::integer( $consume['inc_expert_id'] );
                }
                else
                {
                    if( $consume_user_id != $consume['inc_expert_id'] )
                    {
                        // FUCK &
                    }
                }

                $ingridients[] = '
                    <div class="consume_elem">
                        <span class="reagent_name">'.common::db2html($consume['reactiv_name']).'</span>
                        <span class="quantity">'.common::db2html($consume['quantity']).'</span>
                        <span class="units_short_name">'.common::db2html($units[$consume['reactiv_units_id']]['short_name']).'</span>
                    </div>
                ';
            }

            if( isset($users[$consume_user_id]) )
            {
                foreach( $users[$consume_user_id] as $key => $value )
                {
                    if( is_array($value) ){ continue; }
                    $tags[] = '{tag:user:'.$key.'} : \''.common::db2html( $value ).'\'';
                    $tpl->set( '{tag:user:'.$key.'}',   common::db2html( $value ) );
                }

                $tpl->set( '{tag:user:name:1}',     common::db2html( substr( $users[$consume_user_id]['name']     , 0, 1 ) ) );
                $tpl->set( '{tag:user:surname:1}',  common::db2html( substr( $users[$consume_user_id]['surname']  , 0, 1 ) ) );
                $tpl->set( '{tag:user:phname:1}',   common::db2html( substr( $users[$consume_user_id]['phname']   , 0, 1 ) ) );
            }

                //$tpl->set_block( '!\{tag:recipe:(\w+?)\}!is', '' );

            $tpl->set( '{consume:list}', implode( '', $ingridients ) );


            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function remove( $using_hash = false )
    {
        $using_hash = common::filter_hash( $using_hash );

        if( !$using_hash ){ return self::error( '������������� �� ���������!' ); }

        $data = $this->get_raw( array( 'hash' => $using_hash ) );

        if( !isset($data[$using_hash]) ){ return self::error( '���� �� ��������!' ); }

        $data = $data[$using_hash];

        if( $data['group_id'] != CURRENT_GROUP_ID ){ return self::error( '�� �� ���� ����� �������� ������ � ���� ���������!' ); }
        if( $data['expert_id'] != CURRENT_USER_ID ){ return self::error( '�� �� ���� ����� �������� ��� ������!' ); }
        if( $data['purpose_id'] == 3 ){ return self::error( '����� ����� ����������� ����������� �� �� ���� ���� ���������!' ); }
        if( is_array($data['reactiv_hash']) && count($data['reactiv_hash']) ){ return self::error( '����� ����� ����������� ����������� �� �� ���� ���� ���������!' ); }

        $data['reactiv_consume_hash']   = is_array($data['reactiv_consume_hash'])   ? $data['reactiv_consume_hash'] : $data['reactiv_consume_hash'];
        $data['consume_hash']           = is_array($data['consume_hash'])           ? $data['consume_hash']         : $data['consume_hash'];

        $SQL = array();

        foreach( $data['consume_hash'] as $line )
        {
            $SQL[] = 'DELETE FROM consume_using WHERE using_hash = \''.$this->db->safesql( $data['hash'] ).'\' AND consume_hash = \''.$this->db->safesql( $line['consume_hash'] ).'\'; ';
            $SQL[] = 'DELETE FROM consume WHERE hash = \''.$this->db->safesql( $line['consume_hash'] ).'\'; ';
        }

        foreach( $data['reactiv_consume_hash'] as $line )
        {
            $SQL[] = 'DELETE FROM reactiv_consume_using WHERE using_hash = \''.$this->db->safesql( $data['hash'] ).'\' AND consume_hash = \''.$this->db->safesql( $line['consume_hash'] ).'\'; ';
            $SQL[] = 'DELETE FROM reactiv_consume       WHERE hash = \''.$this->db->safesql( $line['consume_hash'] ).'\'; ';
        }

        $SQL[] = 'DELETE FROM "using" WHERE hash = \''.$this->db->safesql( $data['hash'] ).'\';';

        $this->db->transaction_start();
        $this->db->query( implode( "\n", $SQL ) );
        $this->db->transaction_commit();

        $this->db->free();

        cache::clean();

        return $data['hash'];
    }

    public final function save( $using_hash = false, $data = array() )
    {
        access::check( 'using', 'edit' );

        $date_diap = (60*60*24*356*10);

        $_USING_HASH = common::filter_hash( $using_hash );
        if( !is_array($data) ){ return self::error( '������� �������� �����!' ); }

        /////////
        $data['purpose_id'] = common::integer( isset($data['purpose_id'])?$data['purpose_id']:0 );
        $purpose = ( ( new spr_manager( 'purpose' )   )->get_raw()[$data['purpose_id']] );
        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $recipes = ( new recipes )->get_raw();
        $old_data = $this->get_raw( array( 'hash' => $using_hash ) );

        if( is_array($old_data) && isset($old_data[$using_hash]) )
        {
            $old_data = $old_data[$using_hash];
        }
        else
        {
            $old_data = array();
        }

        /////////



        $data['user_id'] = common::integer( isset($old_data['expert_id']) ? $old_data['expert_id'] : CURRENT_USER_ID );

        //var_export( $old_data );exit;

        $SQL = array();
        $SQL['using'] = array();
        $SQL['using']['date']       = date( 'Y-m-d', common::integer( isset($data['date']) ? strtotime($data['date']) : 0 ) ).' ' . date( 'H:i:s' );
        $SQL['using']['purpose_id'] = common::integer( isset($data['purpose_id']) ? $data['purpose_id'] : false );
        $SQL['using']['group_id']   = CURRENT_GROUP_ID;
        $SQL['using']['exp_number'] = $this->db->safesql( common::filter( isset($data['exp_number']) ? $data['exp_number'] : '' ) );
        //$SQL['using']['exp_date']   = date( 'Y-m-d', common::integer( isset($data['exp_date']) ? strtotime($data['exp_date']) : 0 ) );
        $SQL['using']['obj_count']  = common::integer( isset($data['obj_count']) ? $data['obj_count'] : false );
        $SQL['using']['expert_id']  = common::integer( $data['user_id'] );
        $SQL['using']['tech_info']  = $this->db->safesql( common::filter( isset($data['tech_info']) ? $data['tech_info'] : '' ) );
        $SQL['using']['ucomment']   = $this->db->safesql( common::encode_string( common::trim( common::filter( isset($data['comment']) ? $data['comment'] : '' ) ) ) );

        $SQL['using']['query'] = !$_USING_HASH
            ?   'INSERT INTO "using" '.db::array2ins( $SQL['using'] )
            :   'UPDATE "using" SET '.db::array2upd( $SQL['using'] ).' WHERE group_id = '.CURRENT_GROUP_ID.' AND hash = \''.$this->db->safesql($_USING_HASH).'\' ';
        $SQL['using']['query'] = $SQL['using']['query'].' RETURNING hash;';

        if( isset($old_data['expert_id']) && $old_data['expert_id'] != CURRENT_USER_ID ){ return self::error( '�� �� ������ ���������� ��� ������', false ); }

        if( strtotime($SQL['using']['date']) > time() ){ return self::error( '�� �� ������ ���������� ������ � �����������!', 'date' ); }
        if( strtotime($SQL['using']['date']) < ( time() - $date_diap ) ){ return self::error( '������ ����� ����!', 'date' ); }
        if( !isset($purpose['id']) || !$purpose['id'] ) { return self::error( '�������� �������! �� ������� ��������� ���� ������������!', false ); }
        if( $purpose['attr'] == 'reactiv' ){ return self::error( '����������� ������ ������ ����������!', false ); }

        ///////////////////////

        if( $purpose['attr'] != 'expertise' )
        {
            unset( $SQL['using']['exp_number'] );
            unset( $SQL['using']['obj_count'] );
        }
        else
        {
            if( !$SQL['using']['obj_count'] ){ return self::error( '�������� ������� ��\'����!', 'obj_count' ); }
            if( strlen($SQL['using']['exp_number']) < 2 ){ return self::error( '�������� ����� ��������!', 'exp_number' ); }
            unset( $SQL['using']['tech_info'] );
        }


        $data['consume'] =          array_values( ( isset($data['consume']) && is_array($data['consume']) ) ?$data['consume']:array() );
        $data['reactiv_consume'] =  array_values( ( isset($data['reactiv_consume']) && is_array($data['reactiv_consume']) )?$data['reactiv_consume']:array() );

        if( !count($data['reactiv_consume']) && !count($data['consume']) )
        {
            return self::error( '�� ��������� ����������� ��������/��������!' );
        }


        ///////////////////////
        // STEP 0: BEGIN TRANSACTION
        $this->db->transaction_start();

        ///////////////////////////////
        $SQL['using']['hash'] = $_USING_HASH = $this->db->super_query( $SQL['using']['query'] )['hash'];
        if( !$_USING_HASH )
        {
            $this->db->transaction_rollback();
            return self::error( 'reactiv hash error!' );
        }
        /////////////////

        $SQL['consume'] = array();
        $i = 0;

        $consume = new consume;
        $this->db->super_query( 'DELETE FROM consume_using WHERE using_hash = \''.$_USING_HASH.'\';' );
        $SQL['consume']['reagent'] = array();
        foreach( $data['consume'] as $k=>$ingridient )
        {
            $SQL['consume']['reagent'][$k] = array
            (
                'dispersion_id' => common::integer( $ingridient['dispersion_id'] ),
                'quantity'      => common::numeric(   $ingridient['quantity'] ),
                'inc_expert_id' => common::integer( $data['user_id'] ),
                'date'          => $SQL['using']['date'],
                'hash'          => isset($ingridient['consume_hash']) ? $ingridient['consume_hash'] : false,
            );

            if( $purpose['attr'] == 'utilisation' ){ $SQL['consume']['reagent'][$k]['utilisation'] = 1; }

            $SQL['consume']['reagent'][$k]['hash'] = $consume->save( $SQL['consume']['reagent'][$k] );

            if( $SQL['consume']['reagent'][$k]['hash'] )
            {
                $this->db->super_query( 'INSERT INTO consume_using ( using_hash, consume_hash ) VALUES ( \''.$_USING_HASH.'\', \''.$SQL['consume']['reagent'][$k]['hash'].'\' );' );
            }
            else
            {
                if(
                    isset($GLOBALS['_ajax_result'])
                    && is_array($GLOBALS['_ajax_result'])
                    && isset($GLOBALS['_ajax_result']['error'])
                    && isset($GLOBALS['_ajax_result']['error_text'])
                    && common::integer($GLOBALS['_ajax_result']['error']) > 0
                )
                {
                    return self::error( '������� ���������� ������������ ������� �� ��������!'."\r\n".$GLOBALS['_ajax_result']['error_text'], 'reagent:'.$SQL['consume']['reagent'][$k]['dispersion_id'] );
                }
                else
                {
                    return self::error( '������� ���������� ������������ ������� �� ��������!' );
                }
            }
        }

        $reactiv_consume = new reactiv_consume;
        $this->db->super_query( 'DELETE FROM reactiv_consume_using WHERE using_hash = \''.$_USING_HASH.'\';' );
        $SQL['consume']['reactiv'] = array();
        foreach( $data['reactiv_consume'] as $k=>$ingridient )
        {
            $SQL['consume']['reactiv'][$k] = array
            (
                'reactiv_hash'  => $this->db->safesql(common::filter_hash( $ingridient['reactiv_hash'] )),
                'quantity'      => common::numeric(   $ingridient['quantity'] ),
                'inc_expert_id' => common::integer( $data['user_id'] ),
                'date'          => $SQL['using']['date'],
                'hash'          => isset($ingridient['consume_hash']) ? $ingridient['consume_hash'] : false,
            );

            if( $purpose['attr'] == 'utilisation' ){ $SQL['consume']['reactiv'][$k]['utilisation'] = 1; }

            $SQL['consume']['reactiv'][$k]['hash'] = $reactiv_consume->save( $SQL['consume']['reactiv'][$k] );

            if( $SQL['consume']['reactiv'][$k]['hash'] )
            {
                $this->db->super_query( 'INSERT INTO reactiv_consume_using ( using_hash, consume_hash ) VALUES ( \''.$_USING_HASH.'\', \''.$SQL['consume']['reactiv'][$k]['hash'].'\' );' );
            }
            else
            {
                if(
                    isset($GLOBALS['_ajax_result'])
                    && is_array($GLOBALS['_ajax_result'])
                    && isset($GLOBALS['_ajax_result']['error'])
                    && isset($GLOBALS['_ajax_result']['error_text'])
                    && common::integer($GLOBALS['_ajax_result']['error']) > 0
                )
                {
                    return self::error( '������� ���������� ������������ ��������!'."\r\n".$GLOBALS['_ajax_result']['error_text'], 'reactiv:'.$SQL['consume']['reactiv'][$k]['reactiv_hash'] );
                }
                else
                {
                    return self::error( '������� ���������� ������������ ��������!' );
                }
            }
        }

        $this->db->transaction_commit();

        cache::clean();

        $this->db->free();

        return $_USING_HASH;
    }







    public final function save_template( $data )
    {
        if( !is_array($data) ){ return false; }
        if( !isset($data['name']) ){ return false; }
        if( !is_array($data['ingridients']) || !count($data['ingridients']) ){ return false; }

        $data = common::filter( $data );

        if( strlen($data['name']) > 32 ){ $data['name'] = substr( $data['name'], 0, 32 ); }

        $data['name'] = $this->db->safesql( $data['name'] );
        $data['ingridients'] = common::trim( $data['ingridients'] );
        $data['ingridients'] = common::filter( $data['ingridients'] );

        sort( $data['ingridients'] );

        $data['ingridients'] = implode( ' ; ', $data['ingridients'] );
        $data['ingridients'] = $this->db->safesql( $data['ingridients'] );

        $SQL = 'DELETE FROM templates WHERE expert_id = '.CURRENT_USER_ID.' AND ingridients = \''.$data['ingridients'].'\';';
        $this->db->query( $SQL );

        $SQL = 'INSERT INTO templates ( expert_id, name, ingridients ) VALUES ( '.CURRENT_USER_ID.', \''.$data['name'].'\', \''.$data['ingridients'].'\' ) RETURNING id;';
        $SQL = $this->db->query( $SQL );
        $ID = $SQL ? $this->db->get_row( $SQL ) : array();
        $ID = isset($ID['id']) ? $ID['id'] : false;

        cache::clean('using');
        return $ID;
    }

    public final function remove_template( $id )
    {
        $id = common::integer( $id );
        $SQL = 'DELETE FROM templates WHERE expert_id = '.CURRENT_USER_ID.' AND id = \''.$id.'\';';
        $this->db->query( $SQL );

        $this->db->free();

        cache::clean('using');

        return true;
    }
    public final function get_templates_html()
    {
        $data = array();

        $data[] = '<div data-id="0" class="template" title="��������"><p>-- �������� --</p></div>';

        foreach( $this->get_templates_raw() as $id => $line )
        {
            $data[$id] = '<div class="template" title="'.$line['ingridients'].'" data-ingridients="'.$line['ingridients'].'" data-id="'.$line['id'].'"><p>'.$line['name'].'</p><span class="remove" data-id="'.$line['id'].'"></span></div>';
        }
        return implode( "\n", $data );
    }

    private function get_templates_raw()
    {
        $cache_var = 'using-templates-'.CURRENT_USER_ID;
        $data = cache::get( $cache_var );

        if( $data && is_array($data) ){ return $data; }

        $data = array();

        $SQL = $this->db->query( 'SELECT * FROM templates WHERE expert_id = '.CURRENT_USER_ID.' ORDER BY name ASC;' );
        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $row['ingridients'] = explode( ';', $row['ingridients'] );
            $row['ingridients'] = common::trim( $row['ingridients'] );
            $row['ingridients'] = implode( ' ; ', $row['ingridients'] );
            $data[ $row['id'] ] = common::stripslashes( $row );
        }

        cache::set( $cache_var, $data );
        return $data;
    }







































}