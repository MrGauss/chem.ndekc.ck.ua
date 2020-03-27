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

    public final function remove( $reactiv_hash = 0 )
    {
        $reactiv_hash = common::filter_hash( $reactiv_hash );
        $error = '';

        if( !$error && !$reactiv_hash ){ $error = 'Ідентифікатор не визначено!'; }

        ////////////////////////////////////

        $data = array();
        if( !$error && $reactiv_hash ){ $data = $reactiv_hash?$this->get_raw(array('hash'=>$reactiv_hash))[$reactiv_hash] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) )                                  { $error = 'Помилка отримання даних!'; }
        if( !$error && $data['quantity_left'] != $data['quantity_inc'] )                        { $error = 'Неможливо видалити реактив, який вже почали використовувати!';  }

        ////////////////////////////////////
        if( $error != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), $error ); return false; }
            else        { common::err( $error ); return false; }
        }

        $this->db->query( 'BEGIN;' );
        $this->db->query( '
                                DELETE FROM reactiv USING "using"
                                WHERE
                                        "using".hash            = reactiv.hash
                                    AND "using".purpose_id      = \''.$data['purpose_id'].'\'
                                    AND reactiv.hash            = \''.$data['hash'].'\'
                                    AND reactiv.using_hash      = \''.$data['using_hash'].'\'
                                    AND reactiv.group_id        = '.CURRENT_GROUP_ID.'
                                ;' );

        foreach( $data['composition'] as $ingridient )
        {

            $this->db->query( '
                                DELETE FROM "consume" USING "dispersion"
                                WHERE
                                        dispersion.id       = consume.dispersion_id
                                    AND dispersion.group_id ='.CURRENT_GROUP_ID.'
                                    AND dispersion.id       = \''.$ingridient['dispersion_id'].'\'::INTEGER
                                    AND hash                = \''.$ingridient['consume_hash'].'\'
                                    AND using_hash          = \''.$ingridient['using_hash'].'\'
                                ;' );
        }

        $this->db->query( 'DELETE FROM "using" WHERE hash=\''.$data['using_hash'].'\' AND purpose_id=\''.$data['purpose_id'].'\';' );
        $this->db->query( 'COMMIT;' );

        cache::clean();

        return $reactiv_hash;
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

    public final function save( $reactiv_hash = false, $data = array() )
    {
        $error = false;
        $reactiv_hash = common::filter_hash( $reactiv_hash );

        if( !is_array($data) )            { return self::error( 'Помилка передачі даних!' ); }
        if( !isset($data['composition']) || !is_array($data['composition']) || !count(($data['composition'])) ){ return self::error( 'Відсутня інформація про компоненти!' ); }

        $date_diap = (60*60*24*356*10);

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
        if( !isset($purpose['id']) || !$purpose['id'] ) { return self::error( 'Системна помилка! Не вдалося визначити мету використання!', false ); }

        /////////

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();

        /////////

        $SQL = array();
        $SQL['reactiv'] = array();

        $SQL['reactiv']['reactiv_menu_id'] = common::integer( isset($data['reactiv_menu_id']) ? $data['reactiv_menu_id'] : false );
        $SQL['reactiv']['quantity_inc']    = common::float( isset($data['quantity_inc']) ? $data['quantity_inc'] : false );
        $SQL['reactiv']['inc_expert_id']   = common::integer( isset($data['inc_expert_id']) ? $data['inc_expert_id'] : false );
        $SQL['reactiv']['inc_expert_id']   = $reactiv_hash ? $SQL['reactiv']['inc_expert_id'] : CURRENT_USER_ID;
        $SQL['reactiv']['group_id']        = CURRENT_GROUP_ID;
        $SQL['reactiv']['inc_date']        = date( 'Y-m-d', common::integer( isset($data['inc_date']) ? strtotime($data['inc_date']) : 0 ) );
        $SQL['reactiv']['dead_date']       = date( 'Y-m-d', common::integer( isset($data['dead_date']) ? strtotime($data['dead_date']) : 0 ) );
        $SQL['reactiv']['using_hash']      = common::filter_hash( isset($data['using_hash']) ? $data['using_hash'] : false );
        $SQL['reactiv']['safe_place']      = common::filter( isset($data['safe_place']) ? $data['safe_place'] : false );
        $SQL['reactiv']['safe_needs']      = common::filter( isset($data['safe_needs']) ? $data['safe_needs'] : false );
        $SQL['reactiv']['comment']         = common::filter( isset($data['comment']) ? $data['comment'] : false );

        $_USING_HASH = $SQL['reactiv']['using_hash'];

        if( !$SQL['reactiv']['reactiv_menu_id'] )                                   { return self::error( 'Рецепт приготування не визначено!',              'reactiv_menu_id' ); }
        if( !$SQL['reactiv']['quantity_inc'] )                                      { return self::error( 'Не визначена кількість приготованого реактиву!', 'quantity_inc' ); }
        if( strtotime($SQL['reactiv']['inc_date']) > time() )                       { return self::error( 'Дата приготування не може бути з майбутнього!',   'inc_date' ); }
        if( strtotime($SQL['reactiv']['inc_date']) < ( time() - $date_diap ) )      { return self::error( 'Дата приготування занадто давня!',   'inc_date' ); }

        if( strtotime($SQL['reactiv']['dead_date']) < strtotime($SQL['reactiv']['inc_date']) )  { return self::error( 'Дата зберігання не може бути більшою ніж дата приготування!',   'inc_date|dead_date' ); }
        if( strtotime($SQL['reactiv']['dead_date']) > ( time() + $date_diap ) )                 { return self::error( 'Дата зберігання занадто оптимістична! Ця херня стільки не стоятиме!',   'dead_date' ); }

        if( strlen($SQL['reactiv']['safe_place']) > 250 )   { return self::error( 'Місце зберігання занадто довге!',   'safe_place' ); }
        if( strlen($SQL['reactiv']['safe_place']) < 3 )     { return self::error( 'Місце зберігання занадто коротке!', 'safe_place' ); }

        if( strlen($SQL['reactiv']['safe_needs']) > 250 )   { return self::error( 'Умови зберігання занадто довгі!',   'safe_needs' ); }
        if( strlen($SQL['reactiv']['safe_needs']) < 3 )     { return self::error( 'Умови зберігання занадто короткі!', 'safe_needs' ); }

        if( strlen($SQL['reactiv']['comment']) > 1000 )     { return self::error( 'Коментар занадто довгий! Це поле не для мемуарів!', 'comment' ); }

        $inc_expert = ((new user)->get_user_data_raw( $SQL['reactiv']['inc_expert_id'] ));
            if( !is_array($inc_expert) || !isset($inc_expert[$SQL['reactiv']['inc_expert_id']]) )   { return self::ban( 'Відсутні відомості про експерта! Бан!',    'inc_expert_id' ); }

            $inc_expert = $inc_expert[$SQL['reactiv']['inc_expert_id']];

            if(  common::integer( $inc_expert['group_id'] ) != CURRENT_GROUP_ID )                   { return self::ban( 'Спроба підміни експерта! Бан!',            'inc_expert_id' ); }
            if( !common::integer( $inc_expert['visible'] ) )                                        { return self::error( 'Ви намагаєтесь вказати експерта в якого деактивований обліковий запис!',   'inc_expert_id' ); }

        //////

        $reactiv_menu = ( new recipes )->get_raw( array( 'id' => $SQL['reactiv']['reactiv_menu_id'] ) );
        if( !is_array($reactiv_menu) || !isset($reactiv_menu[$SQL['reactiv']['reactiv_menu_id']]) ){ return self::error( 'Рецепт не знайдено!' ); }
        $reactiv_menu = $reactiv_menu[$SQL['reactiv']['reactiv_menu_id']];

        //////

        $SQL['using'] = array();
        $SQL['using']['date']       = $SQL['reactiv']['inc_date'];
        $SQL['using']['purpose_id'] = $purpose['id'];
        $SQL['using']['group_id']   = CURRENT_GROUP_ID;

        if( strlen($_USING_HASH) != 32 )
        {
            $SQL['using'] = array_map( array( $this->db, 'safesql' ), $SQL['using'] );
            $SQL['using'] = 'INSERT INTO "using" ("'. implode( '", "', array_keys($SQL['using']) ) .'") VALUES (\''. implode( '\', \'', array_values($SQL['using']) ) .'\') RETURNING "hash";';
        }
        else
        {
            $SQL['using'] = array_map( array( $this->db, 'safesql' ), $SQL['using'] );
            foreach( $SQL['using'] as $k => $v ){ $SQL['using'][$k] = '"'.$k.'" = \''.$v.'\' '; }
            $SQL['using'] = 'UPDATE "using" SET '.implode( ', ', $SQL['using'] ).' WHERE "hash" = \''.$_USING_HASH.'\' RETURNING "hash";';
        }

        //////

        $ingredients = array();

        $existed_consume = array();
        if( strlen($reactiv_hash) == 32 )
        {
            $existed_consume = ( new consume )->get_raw( array( 'reactiv_hash' => $reactiv_hash ) );
        }

        $SQL['consume'] = array();
        foreach( $data['composition'] as $ingridient )
        {

            $ingridient['consume_hash'] = common::filter( isset( $ingridient['consume_hash'] ) ? $ingridient['consume_hash'] : false );
            $SQL['consume'][$ingridient['dispersion_id']]['dispersion_id'] = common::integer( $ingridient['dispersion_id'] );
            $SQL['consume'][$ingridient['dispersion_id']]['inc_expert_id'] = common::integer( $SQL['reactiv']['inc_expert_id'] );
            $SQL['consume'][$ingridient['dispersion_id']]['quantity']      = common::float( $ingridient['quantity'] );
            $SQL['consume'][$ingridient['dispersion_id']]['using_hash']    = ( strlen($_USING_HASH) == 32 ) ? $_USING_HASH : '%USING_HASH%';
            $SQL['consume'][$ingridient['dispersion_id']]['date']          = $SQL['reactiv']['inc_date'];


            if( !$SQL['consume'][$ingridient['dispersion_id']]['quantity'] )        { return self::error( 'Не визначена кількість реактиву!' ); }
            if( !$SQL['consume'][$ingridient['dispersion_id']]['dispersion_id'] )   { return self::error( 'Реактив не знайдено в лабораторії!' ); }

            $_disp = ( new dispersion )->get_raw( array( 'id' => $SQL['consume'][$ingridient['dispersion_id']]['dispersion_id'] ) );

            if( !is_array($_disp) || !isset($_disp[$SQL['consume'][$ingridient['dispersion_id']]['dispersion_id']]) )   { return self::error( 'Реактив не знайдено в лабораторії!' ); }

            $_disp = $_disp[$SQL['consume'][$ingridient['dispersion_id']]['dispersion_id']];

            if( $_disp['group_id'] != CURRENT_GROUP_ID )   { return self::error( 'Реактив не знайдено в лабораторії!' ); }

            $uq = 0;
            if( is_array($existed_consume) && isset($existed_consume[$ingridient['consume_hash']]) && isset($existed_consume[$ingridient['consume_hash']]['quantity']) )
            {
                $uq = $existed_consume[$ingridient['consume_hash']]['quantity'];
                $uq = common::float( $uq );
            }

            if( $SQL['consume'][$ingridient['dispersion_id']]['quantity'] > ( common::float($_disp['quantity_left']) + $uq ) )   { return self::error( 'Збавте свій апетит! Такої кількості реактиву в лабораторії немає!' ); }
            if( time() > strtotime($_disp['dead_date']) )   { return self::error( 'Реактив "'.common::trim($reagent[$_disp['reagent_id']]['name']).' ['.common::db2html( $_disp['reagent_number'] ).']" зіпсувався! Його неможна використати!' ); }

            if( !isset( $reactiv_menu['ingredients'][$_disp['reagent_id']] ) ){ return self::error( 'Реактив відсутній в рецепті!' ); }

            $ingredients[] = $_disp['reagent_id'];

            $_disp = null;
            unset( $_disp );

            if( strlen($ingridient['consume_hash']) == 32 )
            {
                $SQL['consume'][$ingridient['dispersion_id']] = array_map( array( $this->db, 'safesql' ), $SQL['consume'][$ingridient['dispersion_id']] );
                $_hash = $SQL['consume'][$ingridient['dispersion_id']]['using_hash'];
                foreach( $SQL['consume'][$ingridient['dispersion_id']] as $k => $v ){ $SQL['consume'][$ingridient['dispersion_id']][$k] = '"'.$k.'" = \''.$v.'\' '; }
                $SQL['consume'][$ingridient['dispersion_id']] = 'UPDATE "consume" SET '.implode( ', ', $SQL['consume'][$ingridient['dispersion_id']] ).' WHERE "hash" = \''.$ingridient['consume_hash'].'\' AND using_hash = \''.$_hash.'\' RETURNING "hash";';
                $_hash = null;
            }
            else
            {
                $SQL['consume'][$ingridient['dispersion_id']] = array_map( array( $this->db, 'safesql' ), $SQL['consume'][$ingridient['dispersion_id']] );
                $SQL['consume'][$ingridient['dispersion_id']] = 'INSERT INTO "consume" ("'. implode( '", "', array_keys($SQL['consume'][$ingridient['dispersion_id']]) ) .'") VALUES (\''. implode( '\', \'', array_values($SQL['consume'][$ingridient['dispersion_id']]) ) .'\') RETURNING "hash";';
            }
        }

        $ingredients = array_unique($ingredients);
        foreach( $ingredients as $ingredient )
        {
            if( isset($reactiv_menu['ingredients'][$ingredient]) )
            {
                unset( $reactiv_menu['ingredients'][$ingredient] );
            }
            else
            {
                return self::error( 'Реактив відсутній в рецепті!' );
            }
        }

        if( count($reactiv_menu['ingredients']) )
        {
            return self::error( 'Ви приготували реактив не за рецептом! Додайте інрідієнти!' );
        }

        if( !count($SQL['consume']) )   { return self::error( 'Не визначений склад реактиву! Додайте інгрідієнти!' ); }


        $SQL['reactiv']['using_hash'] = ( strlen($SQL['reactiv']['using_hash']) == 32 ) ? $SQL['reactiv']['using_hash'] : '%USING_HASH%';
        if( strlen($reactiv_hash) == 32 )
        {
            $SQL['reactiv'] = array_map( array( $this->db, 'safesql' ), $SQL['reactiv'] );
            foreach( $SQL['reactiv'] as $k => $v ){ $SQL['reactiv'][$k] = '"'.$k.'" = \''.$v.'\' '; }
            $SQL['reactiv'] = 'UPDATE "reactiv" SET '.implode( ', ', $SQL['reactiv'] ).' WHERE "hash" = \''.$reactiv_hash.'\' RETURNING "hash";';
        }
        else
        {
            $SQL['reactiv'] = array_map( array( $this->db, 'safesql' ), $SQL['reactiv'] );
            $SQL['reactiv'] = 'INSERT INTO "reactiv" ("'. implode( '", "', array_keys($SQL['reactiv']) ) .'") VALUES (\''. implode( '\', \'', array_values($SQL['reactiv']) ) .'\') RETURNING "hash";';
        }

        ////////////////////////////////////

        $this->db->query( 'BEGIN;' );

        ////////////////////////////////////
        // STEP 1
        // INSERT OR UPDATE "using"
        $SQL['using'] = $this->db->get_row( $this->db->query( $SQL['using'] ) )['hash'];

        if( strlen($_USING_HASH) == 32 && $_USING_HASH != $SQL['using'] )
        {
            $this->db->query( 'ROLLBACK;' );
            return self::error( 'Помилка запису даних! Отриманий хеш з таблиці використання ("using") не співпадає з переданим! Це срака...' );
        }

        $_USING_HASH  = $SQL['using'];
        ////////////////////////////////////


        ////////////////////////////////////
        // STEP 2
        // INSERT OR UPDATE "consume"
        foreach( $SQL['consume'] as $k => $v )
        {
            $v = str_replace( '%USING_HASH%', $SQL['using'], $v );
            $SQL['consume'][$k] = $this->db->get_row( $this->db->query( $v ) )['hash'];

            if( !$SQL['consume'][$k] || strlen($SQL['consume'][$k]) != 32 )
            {
                $this->db->query( 'ROLLBACK;' );
                return self::error( 'Помилка запису даних! Отриманий хеш з таблиці ("consume") не співпадає з переданим! Це срака...' );
            }
        }
        ////////////////////////////////////

        ////////////////////////////////////
        // STEP 3
        // INSERT OR UPDATE "reactiv"
        $SQL['reactiv'] = str_replace( '%USING_HASH%', $SQL['using'], $SQL['reactiv'] );
        $SQL['reactiv'] = $this->db->get_row( $this->db->query( $SQL['reactiv'] ) )['hash'];

        if( !$SQL['reactiv'] || strlen($SQL['reactiv']) != 32 || ( strlen($reactiv_hash) == 32 && $SQL['reactiv'] != $reactiv_hash ) )
        {
            $this->db->query( 'ROLLBACK;' );
            return self::error( 'Помилка запису даних! Отриманий хеш з таблиці використання ("reactiv") не співпадає з переданим! Це срака...' );
        }
        ////////////////////////////////////

        $this->db->query( 'COMMIT;' );

        cache::clean();
        return $SQL['reactiv'];
    }


    public final function editor( $line_hash = false, $skin = false )
    {
        $line_hash = common::filter_hash( $line_hash );

        $data = $this->get_raw( array( 'hash' => $line_hash ) );

        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : false;



        if( !is_array($data) ){ return false; }

        if( !$data['inc_expert_id'] ){ $data['inc_expert_id'] = CURRENT_USER_ID; }

        $tpl = new tpl;

        $tpl->load( $skin );

        $_dates = array();
        $_dates[] = 'inc_date';
        $_dates[] = 'dead_date';

        foreach( $_dates as $_date )
        {
            $data[$_date]       = isset($data[$_date])      ? common::en_date( $data[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
            if( strpos( $data[$_date], '.197' ) !== false ){ $data[$_date] = date('d.m.Y'); }
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

        $purpose        = ( new spr_manager( 'purpose' ) )    ->get_raw();
        $units          = ( new spr_manager( 'units' ) )    ->get_raw();
        $reagent        = ( new spr_manager( 'reagent' ) )  ->get_raw();
        $reactiv_menu   = ( new recipes )                   ->get_raw();

        $_dates = array();
        $_dates[] = 'inc_date';
        $_dates[] = 'dead_date';

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tags = array();

            $tpl->load( $skin );

            $line['not_used_perc'] = common::compare_perc( $line['quantity_inc'], $line['quantity_left'] );

            if( $line['not_used_perc'] <= 1 )                                { $tpl->set( '{tag:not_used_class}',   'fully_used' ); }
            if( $line['not_used_perc'] >  1 && $line['not_used_perc'] <= 10 ){ $tpl->set( '{tag:not_used_class}',   'almost_used' ); }
            if( $line['not_used_perc'] > 10 && $line['not_used_perc'] <= 50 ){ $tpl->set( '{tag:not_used_class}',   'half_used' ); }
            if( $line['not_used_perc'] > 50 )                                { $tpl->set( '{tag:not_used_class}',   'not_used' ); }

            $line['lifetime'] = strtotime( common::en_date( $line['dead_date'], 'Y-m-d 00:00:01' ) ) - strtotime( date( 'Y-m-d 00:00:01', time() ) );
            if( $line['lifetime'] < 0 )
            {
                $line['lifetime'] = 'gone';
            }
            else
            {
                $line['lifetime'] = floor( $line['lifetime'] / ( 60*60*24 ) );
            }

            foreach( $_dates as $_date )
            {
                $line[$_date]       = isset($line[$_date])      ? common::en_date( $line[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
                if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
            }

            $line['numi'] = $I--;

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }

                $tags[] = '{tag:'.$key.'}';

                $tpl->set( '{tag:'.$key.'}', common::db2html( $value ) );
            }

            if( isset( $reactiv_menu[$line['reactiv_menu_id']] ) )
            {
                foreach( $reactiv_menu[$line['reactiv_menu_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:menu:'.$key.'}';
                    $tpl->set( '{tag:menu:'.$key.'}', common::db2html( $value ) );
                }
            }

            if( isset( $units[$line['reactiv_units_id']] ) )
            {
                foreach( $units[$line['reactiv_units_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:units:'.$key.'}';
                    $tpl->set( '{tag:units:'.$key.'}', common::db2html( $value ) );
                }
            }

            if( isset( $purpose[$line['purpose_id']] ) )
            {
                foreach( $purpose[$line['purpose_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:purpose:'.$key.'}';
                    $tpl->set( '{tag:purpose:'.$key.'}', common::db2html( $value ) );
                }
            }

            if( isset( $line['composition'] ) && is_array($line['composition']) && count($line['composition']) )
            {
                foreach( $line['composition'] as $k => $comp )
                {
                    $line['composition'][$k] = '    <div class="compos">
                                                        <span class="name">'    . common::db2html( $reagent[$comp['reagent_id']]['name'] .' ['.$comp['reagent_number'].']' ) .'</span>
                                                        <span class="quantity">'. common::db2html( $comp['quantity'] ).'</span>
                                                        <span class="units">'   . common::db2html( $units[$reagent[$comp['reagent_id']]['units_id']]['short_name'] ).'</span>
                                                    </div>';
                }
                $line['composition'] = implode( '', $line['composition'] );
            }
            else
            {
                $line['composition'] = '';
            }

            $tags[] = '{tag:composition:html}';
            $tpl->set( '{tag:composition:html}', $line['composition'] );

            $tpl->compile( $skin );
        }



        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
        if( is_array($filters) )
        {
            if( isset($filters['hash']) )
            {
                $filters['hash'] = common::filter_hash( $filters['hash'] );
                $filters['hash'] = is_array($filters['hash']) ? $filters['hash'] : array( $filters['hash'] );
            }

            if( isset($filters['using_hash']) )
            {
                $filters['using_hash'] = common::filter_hash( $filters['using_hash'] );
                $filters['using_hash'] = is_array($filters['using_hash']) ? $filters['using_hash'] : array( $filters['using_hash'] );
            }
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
                    LEFT JOIN "using" ON ( "using".hash = reactiv.using_hash AND reactiv.group_id = "using".group_id )
            WHERE
                '.(( isset($filters['hash'])        && count($filters['hash'])       ) ? 'reactiv.hash IN (\''.implode( '\', \'', $filters['hash'] ).'\')'       : 'reactiv.hash != \'\'').'
                '.(( isset($filters['using_hash'])  && count($filters['using_hash']) ) ? 'AND "using".hash IN (\''.implode( '\', \'', $filters['using_hash'] ).'\')' : '').'
                AND ( reactiv.group_id = \''.CURRENT_GROUP_ID.'\'::INTEGER OR reactiv.group_id = 0 )
            ORDER by
                reactiv.inc_date DESC;
                '.db::CACHED;

        $cache_var = 'spr-reactiv-'.md5( $SQL ).'-raw';
        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $row['hash'] = common::filter_hash( $row['hash'] );
            $data[$row['hash']] = $row;
            $data[$row['hash']]['composition'] = array();
        }

        //////////////////////////////////////////////////////////////////////////////////
        if( is_array($data) && count($data) )
        {
            foreach( (new consume)->get_raw( array( 'reactiv_hash' => array_keys( $data ) ) ) as $consume_hash => $consume_data )
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

        //var_export($data);exit;

        cache::set( $cache_var, $data );
        return $data;
    }

}