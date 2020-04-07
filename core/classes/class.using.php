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

    public final function editor( $line_hash = '', $skin = false )
    {
        $line_hash = common::filter_hash( $line_hash );

        $data = $this->get_raw( array( 'hash' => $line_hash ) );
        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : false;

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

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_hash );

        if( !$data['purpose_id'] ){ $data['purpose_id'] = 1; }

        $tags = array();

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tags[] = '{tag:'.$k.'}';

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            $tpl->set( '{autocomplete:'.$k.':key}', autocomplete::key( 'stock', $k ) );
        }

        if( $data['reactiv_hash'] && $data['reactiv_menu_id'] && isset($data['cooked_reactives']) && is_array($data['cooked_reactives']) && count($data['cooked_reactives']) )
        {
            foreach( $data['cooked_reactives'][$data['reactiv_hash']] as $k => $v )
            {
                if( is_array($v) ){ continue; }

                $tpl->set( '{tag:reactiv:'.$k.'}', common::db2html( $v ) );

                $tags[] = '{tag:reactiv:'.$k.'}';
            }

            $tpl->set( '{tag:reactiv:units:short_name}', ( new spr_manager( 'units' ) )->get_raw()[$data['cooked_reactives'][$data['reactiv_hash']]['reactiv_units_id']]['short_name'] );;
        }

        $tpl->set( '{autocomplete:table}', 'stock' );
        $tpl->set( '{consume:list}',         $this->get_html_consume( $data['consume'], 'using/consume_line' ) );
        $tpl->set( '{reactiv_consume:list}', $this->get_html_consume( $data['reactiv_consume'], 'using/reactiv_consume_line' ) );

        $tpl->set( '{cooked:list}',      ( new cooked )     ->get_html( array( 'quantity_left:more' => 0 ), 'using/selectable_element_cooked' ) );
        $tpl->set( '{dispersion:list}',  ( new dispersion ) ->get_html( array( 'quantity_left:more' => 0 ), 'using/selectable_element_dispersion' ) );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }


    public final function get_html_consume( $data = array(), $skin = false )
    {
        $data = is_array($data) ? $data : array();

        if( !count($data) ){ return ''; }

        $_dates = array();
        $_dates[] = 'consume_ts';
        $_dates[] = 'consume_date';
        $_dates[] = 'using_date';
        $_dates[] = 'dispersion_inc_date';
        $_dates[] = 'reactiv_inc_date';
        $_dates[] = 'reactiv_dead_date';
        $_dates[] = 'using_date';
        $_dates[] = 'consume_date';

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();

        $tpl = new tpl;

        $I = count( $data );

        $reactives_filters                  = array();
        $reactives_filters['hash']          = array();
        $reactives_filters['using_hash']    = array();

        foreach( $data as $line )
        {
            $tpl->load( $skin );

            if( isset($line['reactiv_hash']) ){ $reactives_filters['hash'][]        = $line['reactiv_hash']; }
            if( isset($line['reactiv_hash']) ){ $reactives_filters['using_hash'][]  = $line['using_hash']; }

            $line['key'] = common::key_gen( $line['consume_hash'] );

            $tags = array();

            foreach( $_dates as $_date )
            {
                if( !isset($line[$_date]) ){ continue; }

                $line[$_date] = common::en_date( $line[$_date], 'd.m.Y' );
                if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
            }

            $line['numi'] = $I--;

            $line['dispersion_quantity_left'] = common::float( $line['dispersion_quantity_left'] ) + common::float( $line['quantity'] );

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }

                $tags[] = '{tag:'.$key.'}';
                $tpl->set( '{tag:'.$key.'}', common::db2html( $value ) );
            }

            if( isset($line['reagent_id']) )
            {
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
            }

            if( count($reactives_filters['hash']) && count($reactives_filters['using_hash']) )
            {
                foreach( (new cooked)->get_raw( $reactives_filters ) as $reactive )
                {
                    $reactive['inc_date_unix']  = strtotime( $reactive['inc_date'] );
                    $reactive['dead_date_unix'] = strtotime( $reactive['dead_date'] );

                    $reactive['inc_date'] = common::en_date( $reactive['inc_date'], 'd.m.Y' );
                    $reactive['dead_date'] = common::en_date( $reactive['dead_date'], 'd.m.Y' );

                    foreach( $reactive as $key => $value )
                    {
                        if( is_array($value) ){ continue; }

                        $tags[] = '{cooked:'.$key.'}';
                        $tpl->set( '{cooked:'.$key.'}', common::db2html( $value ) );
                    }

                    if( isset($units[$reactive['reactiv_units_id']]) )
                    {
                        foreach( $units[$reactive['reactiv_units_id']] as $key => $value )
                        {
                            if( is_array($value) ){ continue; }

                            $tags[] = '{cooked:units:'.$key.'}';
                            $tpl->set( '{cooked:units:'.$key.'}', common::db2html( $value ) );
                        }
                    }

                }
            }

            $tpl->compile( $skin );
        }

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

        $purpose = ( new spr_manager( 'purpose' )   )->get_raw();
        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $recipes = ( new recipes() )->get_raw();

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );

            $line['numi'] = $I--;

            $tags = array();

            foreach( $_dates as $_date )
            {
                if( !isset($line[$_date]) ){ continue; }
                $line[$_date] = common::en_date( $line[$_date], 'd.m.Y' );
                if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
            }

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tags[] = '{tag:'.$key.'} : \''.common::db2html( $value ).'\'';
                $tpl->set( '{tag:'.$key.'}', common::db2html( $value ) );
            }
            $tpl->set_block( '!\{tag:(\w+?)\}!is', '' );

            foreach( isset($purpose[$line['purpose_id']])?$purpose[$line['purpose_id']]:array() as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tags[] = '{tag:purpose:'.$key.'} : \''.common::db2html( $value ).'\'';
                $tpl->set( '{tag:purpose:'.$key.'}', common::db2html( $value ) );
            }
            $tpl->set_block( '!\{tag:purpose:(\w+?)\}!is', '' );

            foreach( isset($recipes[$line['reactiv_menu_id']])?$recipes[$line['reactiv_menu_id']]:array() as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tags[] = '{tag:recipe:'.$key.'} : \''.common::db2html( $value ).'\'';
                $tpl->set( '{tag:recipe:'.$key.'}', common::db2html( $value ) );
            }
            $tpl->set_block( '!\{tag:recipe:(\w+?)\}!is', '' );

            $tpl->set( '{consume:list}', $this->get_html_consume( isset($line['consume'])?$line['consume']:array(), 'using/consume_elem' ) );

            // echo implode( "\n", $tags ); echo "\n\n\n"; var_export($line);exit;

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
        $filters = is_array($filters) ? $filters : array();
        $WHERE = array();

        if( isset($filters['hash']) )
        {
            $filters['hash'] = common::filter_hash( $filters['hash']?$filters['hash']:'' );
            $filters['hash'] = is_array($filters['hash']) ? $filters['hash'] : array( $filters['hash'] );

            $filters['hash'] = array_unique($filters['hash']);

            $WHERE['hash']   = '"using".hash IN(\''. implode( '\', \'', array_values( $filters['hash'] ) ) .'\')';
        }
        else
        {
            $WHERE['hash']       = '"using".hash != \'\'';
        }

        $WHERE['group_id']   = '( "using".group_id = '.CURRENT_GROUP_ID.' OR "using".group_id = 0 )';

        /////////////////////

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        /////////////////////

        $SQL = '
            SELECT
                "using".*,
                reactiv.hash as reactiv_hash,
                reactiv.reactiv_menu_id as reactiv_menu_id
            FROM
                "using"
                LEFT JOIN reactiv ON( reactiv.using_hash = "using".hash )
            '.$WHERE.'
            ORDER BY "using"."date" DESC
            ;';

        $cache_var = 'using-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );
        if( $data && is_array($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        $reactives = array();

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['hash']            = common::filter_hash( $row['hash'] ? $row['hash'] : '' );
            $row['reactiv_hash']    = common::filter_hash( $row['reactiv_hash'] ? $row['reactiv_hash'] : '' );
            $row['reactiv_menu_id'] = common::integer( $row['reactiv_menu_id'] );

            $reactives[$row['hash']] = $row['reactiv_hash'];

            $data[$row['hash']] = $row;
            $data[$row['hash']]['ucomment'] = common::decode_string( common::stripslashes( $data[$row['hash']]['ucomment'] ) );
            $data[$row['hash']]['consume']            = array();
            $data[$row['hash']]['reactiv_consume']    = array();
            $data[$row['hash']]['cooked_reactives']   = array();
        }



        foreach( (new consume)->get_raw( array(  'using_hash' => array_keys( $data ) ) ) as $consume )
        {
            if( !isset($data[$consume['using_hash']]) || !is_array($data[$consume['using_hash']]['consume']) )
            {
                common::err( 'Помилка отримання даних!' );
            }

            $data[$consume['using_hash']]['consume'][$consume['consume_hash']] = $consume;
        }

        foreach( (new reactiv_consume)->get_raw( array(  'using_hash' => array_keys( $data ) ) ) as $consume )
        {
            if( !isset($data[$consume['using_hash']]) || !is_array($data[$consume['using_hash']]['reactiv_consume']) )
            {
                common::err( 'Помилка отримання даних!' );
            }

            $data[$consume['using_hash']]['reactiv_consume'][$consume['consume_hash']] = $consume;
        }

        foreach( ( new cooked )->get_raw( array(  'using_hash' => array_keys( $data ) ) ) as $ractive )
        {
            if( !isset($data[$ractive['using_hash']]) || !is_array($data[$ractive['using_hash']]['cooked_reactives']) )
            {
                common::err( 'Помилка отримання даних!' );
            }

            $data[$consume['using_hash']]['cooked_reactives'][$ractive['hash']] = $ractive;
        }

        return $data;
    }

    public final static function error( $error, $error_area = false )
    {
        if( $error != false )
        {
            if( _AJAX_ )
            {
                ajax::set_error( rand(10,99), $error );
                ajax::set_data( 'err_area', isset($error_area) ? $error_area : '' );
                return false;
            }
            else
            {
                common::err( $error );
                return false;
            }
        }
        return true;
    }

    public final function save( $using_hash = false, $data = array() )
    {
        $error = false;
        $using_hash = common::filter_hash( $using_hash );

        if( !is_array($data) )            { return self::error( 'Помилка передачі даних!' ); }
        //if( !isset($data['composition']) || !is_array($data['composition']) || !count(($data['composition'])) ){ return self::error( 'Відсутня інформація про компоненти!' ); }

        $date_diap = (60*60*24*356*10);

        /////////
        $data['purpose_id'] = common::integer( isset($data['purpose_id'])?$data['purpose_id']:0 );

        $purpose = ( ( new spr_manager( 'purpose' )   )->get_raw()[$data['purpose_id']] );
        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();

        /////////

        if( !isset($purpose['id']) || !$purpose['id'] ) { return self::error( 'Системна помилка! Не вдалося визначити мету використання!', false ); }
        if( $purpose['attr'] == 'reactiv' ){ return self::error( 'Редагування даного запису заборонено!', false ); }

        /////////

        $SQL = array();
        $SQL['using'] = array();
        $SQL['using']['date']       = date( 'Y-m-d', common::integer( isset($data['date']) ? strtotime($data['date']) : 0 ) );
        $SQL['using']['purpose_id'] = common::integer( isset($data['purpose_id']) ? $data['purpose_id'] : false );
        $SQL['using']['group_id']   = CURRENT_GROUP_ID;
        $SQL['using']['exp_number'] = common::filter( isset($data['exp_number']) ? $data['exp_number'] : '' );
        $SQL['using']['exp_date']   = date( 'Y-m-d', common::integer( isset($data['exp_date']) ? strtotime($data['exp_date']) : 0 ) );
        $SQL['using']['obj_count']  = common::integer( isset($data['obj_count']) ? $data['obj_count'] : false );
        $SQL['using']['tech_info']  = common::filter( isset($data['tech_info']) ? $data['tech_info'] : '' );
        $SQL['using']['ucomment']   = common::encode_string( common::trim( common::filter( isset($data['comment']) ? $data['comment'] : '' ) ) );

        ///////////////////////

        if( strtotime($SQL['using']['date']) > time() ){ return self::error( 'Ви не можете створювати записи в майбутньому!', 'date' ); }
        if( strtotime($SQL['using']['date']) < ( time() - $date_diap ) ){ return self::error( 'Дуууже давня дата!', 'date' ); }

        ///////////////////////

        if( $purpose['attr'] != 'expertise' )
        {
            unset( $SQL['using']['exp_number'] );
            unset( $SQL['using']['exp_date'] );
            unset( $SQL['using']['obj_count'] );
        }
        else
        {
            if( strtotime($SQL['using']['exp_date']) < strtotime($SQL['using']['date']) ){ return self::error( 'Дата експертизи не може бути меншою за дату використання!', 'date|exp_date' ); }
            if( strtotime($SQL['using']['exp_date']) > time() ){ return self::error( 'Ви не можете створювати записи в майбутньому!', 'exp_date' ); }
            if( strtotime($SQL['using']['exp_date']) < ( time() - $date_diap ) ){ return self::error( 'Дуууже давня дата експертизи!', 'exp_date' ); }

            if( !$SQL['using']['obj_count'] ){ return self::error( 'Зазначте кількість об\'єктів!', 'obj_count' ); }
            if( strlen($SQL['using']['exp_number']) < 2 ){ return self::error( 'Зазначте номер висновку!', 'exp_number' ); }
        }

        if( $purpose['attr'] != 'reactiv' )
        {

        }

        if( $purpose['attr'] != 'maintenance' )
        {
            unset( $SQL['using']['tech_info'] );
        }

        ///////////////////////

        $USING_QUERY = false;
        if( $using_hash )
        {
            $USING_QUERY = array();
            foreach( array_map( array( &$this->db, 'safesql' ), $SQL['using'] ) as $k=>$v )
            {
                $USING_QUERY[] = '"'.$k.'"=\''.$v.'\'';
            }
            $USING_QUERY = 'UPDATE "using" SET '.implode( ', ', $USING_QUERY ).' WHERE "hash"=\''.$this->db->safesql( $using_hash ).'\' RETURNING "hash";';
        }
        else
        {
            $USING_QUERY = array_map( array( &$this->db, 'safesql' ), $SQL['using'] );
            $USING_QUERY = 'INSERT INTO "using" ("'.implode( '", "', array_keys( $USING_QUERY ) ).'") VALUES( \''.implode( '\', \'', array_values( $USING_QUERY ) ).'\' ) RETURNING "hash";';
        }

        /////////////////

        $CONSUME_QUERY = array();
        $SQL['consume'] = array();

        foreach( isset($data['consume'])?$data['consume']:array() as $k=>$consume_data )
        {
            $consume_hash = common::filter_hash( isset($consume_data['consume_hash']) ? $consume_data['consume_hash'] : false );
            $consume_data['key'] = isset($consume_data['key']) ? $consume_data['key'] : false;

            if( $consume_hash && $consume_data['key'] && !common::key_check( $consume_hash, $consume_data['key'] ) )
            {
                return self::error( 'Помилка даних! Виявлено розбіжності в ідентифікаторах!', false );
            }

            $SQL['consume'][$k] = array();
            $SQL['consume'][$k]['dispersion_id']    = common::integer( isset($consume_data['dispersion_id']) ? $consume_data['dispersion_id'] : false );
            $SQL['consume'][$k]['quantity']         = common::float( isset($consume_data['quantity']) ? $consume_data['quantity'] : false );
            $SQL['consume'][$k]['inc_expert_id']    = CURRENT_USER_ID;
            $SQL['consume'][$k]['using_hash']       = '%USING_HASH%';
            $SQL['consume'][$k]['date']             = $SQL['using']['date'];

            if( !$SQL['consume'][$k]['dispersion_id'] )
            {
                return self::error( 'Помилка даних! Реактив не знайдено!', false );
            }

            $reactive = ( new dispersion )->get_raw( array( 'id' => $SQL['consume'][$k]['dispersion_id'] ) )[$SQL['consume'][$k]['dispersion_id']];
            $consume  = $consume_hash ? ( new consume )->get_raw( array( 'hash' => $consume_hash ) ) : array();
            $consume  = isset($consume[$consume_hash])?$consume[$consume_hash] : array();

            if( !isset($reactive['reagent_id']) || !isset($reagent[$reactive['reagent_id']]) )  { return self::error( 'Реактив не знайдено!', false ); }
            if( strtotime($SQL['using']['date']) > strtotime( $reactive['dead_date'] ) )        { return self::error( 'Реактив "'. ( $reagent[$reactive['reagent_id']]['name'] ) .'" зіпсований!', false ); }

            if( common::float( $consume_data['quantity'] ) > common::float( $reactive['quantity_left'] ) + common::float( isset($consume['quantity']) ? $consume['quantity'] : 0 )  ){ return self::error( 'Ви намагаєтесь використати забагато реактиву!', false ); }

            if( common::integer( $reactive['group_id'] ) != CURRENT_GROUP_ID ){ return self::error( 'Реактив знаходиться в іншій лабораторії!', false ); }

            // echo "consume_data:\n"; var_export($consume_data); echo "\n\nconsume:\n"; var_export($consume); echo "\n\nreactive:\n"; var_export($reactive); exit;

            if( $consume_hash )
            {
                $CONSUME_QUERY[$k] = array();
                foreach( array_map( array( &$this->db, 'safesql' ), $SQL['consume'][$k] ) as $tag=>$v )
                {
                    $CONSUME_QUERY[$k][] = '"'.$tag.'"=\''.$v.'\'';
                }
                $CONSUME_QUERY[$k] = 'UPDATE "consume" SET '.implode( ', ', $CONSUME_QUERY[$k] ).' WHERE "hash"=\''.$this->db->safesql( $consume_hash ).'\' AND "using_hash"=\'%USING_HASH%\';';
            }
            else
            {
                $CONSUME_QUERY[$k] = array_map( array( &$this->db, 'safesql' ), $SQL['consume'][$k] );
                $CONSUME_QUERY[$k] = 'INSERT INTO "consume" ("'.implode( '", "', array_keys( $CONSUME_QUERY[$k] ) ).'") VALUES( \''.implode( '\', \'', array_values( $CONSUME_QUERY[$k] ) ).'\' );';
            }
        }

        ////////////////

        $err = false;
        $this->db->query( 'BEGIN;' );

        /////////////////

        $USING_HASH_FROM_DB = $this->db->super_query( $USING_QUERY )['hash'];

        if( $using_hash && $using_hash != $USING_HASH_FROM_DB ) { return self::error( 'Помилка збереження даних!', false ); }

        if( !$err && count($CONSUME_QUERY) )
        {
            $CONSUME_QUERY = implode( "\n", $CONSUME_QUERY );
            $CONSUME_QUERY = str_replace( '%USING_HASH%', $USING_HASH_FROM_DB, $CONSUME_QUERY );
            $this->db->query( $CONSUME_QUERY );
        }

        if( !$err )
        {
            $this->db->query( 'COMMIT;' );
            cache::clean();
            return $USING_HASH_FROM_DB;
        }

        $this->db->query( 'ROLLBACK;' );
        return self::error( $err, false );
    }







































}