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
    private $TRANSACTION_STARTED = false;



    public final function remove( $reactiv_hash = 0 )
    {
        $reactiv_hash = common::filter_hash( $reactiv_hash );
        $error = '';

        if( !$error && !$reactiv_hash ){ return self::error( 'Ідентифікатор не визначено!' ); }

        if( $reactiv_hash && $this->is_used($reactiv_hash) )
        {
            return self::error( 'Даний розчин вже почали використовувати! Редагування заборонено!');
        }

        $data = array();
        if( !$error && $reactiv_hash ){ $data = $reactiv_hash?$this->get_raw(array('hash'=>$reactiv_hash))[$reactiv_hash] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) )                                  { return self::error( 'Помилка отримання даних!' ); }
        if( !$error && $data['quantity_left'] != $data['quantity_inc'] )                        { return self::error( 'Неможливо видалити реактив, який вже почали використовувати!' );  }

        ////////////////////////////////////

        $SQL = array();

        $SQL[] = 'DELETE FROM reactiv WHERE hash = \''. $reactiv_hash .'\';';
        $SQL[] = 'DELETE FROM reactiv_ingr_reactiv WHERE reactiv_hash = \''. $reactiv_hash .'\';';
        $SQL[] = 'DELETE FROM reactiv_ingr_reagent WHERE reactiv_hash = \''. $reactiv_hash .'\';';

        foreach( $data['composition'] as $area => $list )
        {
            foreach( $list as $ingridient )
            {
                if( $area == 'reagent' )
                {
                    $SQL[] = 'DELETE FROM consume WHERE hash = \''. $ingridient['consume_hash'] .'\';';
                    $SQL[] = 'DELETE FROM "using" WHERE hash = \''. $ingridient['using_hash'] .'\';';
                    $SQL[] = 'DELETE FROM consume_using WHERE using_hash = \''. $ingridient['using_hash'] .'\' AND consume_hash = \''. $ingridient['consume_hash'] .'\';';
                }
                if( $area == 'reactiv' )
                {
                    $SQL[] = 'DELETE FROM reactiv_consume WHERE hash = \''. $ingridient['consume_hash'] .'\';';
                    $SQL[] = 'DELETE FROM "using" WHERE hash = \''. $ingridient['using_hash'] .'\';';
                    $SQL[] = 'DELETE FROM reactiv_consume_using WHERE using_hash = \''. $ingridient['using_hash'] .'\' AND consume_hash = \''. $ingridient['consume_hash'] .'\';';
                }
            }
        }

        $SQL = implode( "\n", $SQL );

        $this->db->query( 'BEGIN;' );
        $this->db->query( $SQL );
        $this->db->query( 'COMMIT;' );

        cache::clean();

        return $reactiv_hash;
    }




    public final function update_reactiv_ingr_reagent( $reactiv_hash = false, $consume_hash = array() )
    {
        $reactiv_hash = common::filter_hash( $reactiv_hash );

        if( !$reactiv_hash ){ return false; }

        $reactiv_hash = $this->db->safesql($reactiv_hash);

        $this->db->query( 'DELETE FROM reactiv_ingr_reagent WHERE reactiv_hash=\''.$reactiv_hash.'\';' );

        if( !is_array($consume_hash) ){ return false; }

        $ins = array();
        foreach( $consume_hash as $hash )
        {
            $hash = common::filter_hash( $hash );
            if( $hash ){ $ins[] = '( \''. $reactiv_hash .'\', \''. $hash .'\' )'; }
        }

        if( count($ins) )
        {
            $ins = 'INSERT INTO reactiv_ingr_reagent ( reactiv_hash, consume_hash ) VALUES '.implode( ', ', $ins ).';';
            $this->db->query( $ins );
        }

        return true;
    }

    public final function update_reactiv_ingr_reactiv( $reactiv_hash = false, $consume_hash = array() )
    {
        $reactiv_hash = common::filter_hash( $reactiv_hash );

        if( !$reactiv_hash ){ return false; }

        $reactiv_hash = $this->db->safesql($reactiv_hash);

        $this->db->query( 'DELETE FROM reactiv_ingr_reactiv WHERE reactiv_hash=\''.$reactiv_hash.'\';' );

        if( !is_array($consume_hash) ){ return false; }

        $ins = array();
        foreach( $consume_hash as $hash )
        {
            $hash = common::filter_hash( $hash );
            if( $hash ){ $ins[] = '( \''. $reactiv_hash .'\', \''. $hash .'\' )'; }
        }

        if( count($ins) )
        {
            $ins = 'INSERT INTO reactiv_ingr_reactiv ( reactiv_hash, consume_hash ) VALUES '.implode( ', ', $ins ).';';
            $this->db->query( $ins );
        }

        return true;
    }

    public final function is_used( $reactiv_hash = false )
    {
        $reactiv_hash = common::filter_hash( $reactiv_hash );

        if( !$reactiv_hash ){ return false; }

        $count = 'SELECT count( hash ) as count FROM reactiv_consume WHERE reactiv_hash = \''.$this->db->safesql($reactiv_hash).'\';';
        $count = $this->db->super_query( $count );
        $count = isset($count['count']) ? $count['count'] : 0;
        $count = common::integer( $count ) > 0 ? true : false;

        return $count;
    }

    public final function save( $reactiv_hash = false, $data = array() )
    {
        ////////////////////////////////////////////////////////
        // Алгоритм збереження:
        //  0. Починаємо транзакцію
        //  1. Створюємо запис в таблиці "reactiv", отримуємо [reactiv.hash]
        //  2. За необхідності створюємо запис в таблиці "consume", отримуємо [consume.hash]
        //      2.0. Видаляємо записи з таблиці "reactiv_ingr_reagent" де: reactiv_ingr_reagent.reactiv_hash = reactiv.hash
        //      2.1. Створюємо поєднуючі записи в таблиці "reactiv_ingr_reagent"    -> ( reactiv.hash, consume.hash )
        //  3. За необхідності створюємо запис в таблиці "reactiv_consume", отримуємо [reactiv_consume.hash]
        //      3.0. Видаляємо записи з таблиці "reactiv_ingr_reactiv" де: reactiv_ingr_reactiv.reactiv_hash = reactiv.hash
        //      3.1. Створюємо поєднуючі записи в таблиці "reactiv_ingr_reactiv"    -> ( reactiv.hash, reactiv_consume.hash )
        //  4. Створюємо запис в таблиці "using", отримуємо [using.hash]
        //      4.0  Видаляємо записи з таблиці "reactiv_consume_using" де: reactiv_consume_using.using_hash = using.hash
        //      4.1. Створюємо поєднуючі записи в таблиці "reactiv_consume_using"   -> ( using.hash, reactiv_consume.hash )
        //      4.2  Видаляємо записи з таблиці "consume_using" де: consume_using.using_hash = using.hash
        //      4.3. Створюємо поєднуючі записи в таблиці "consume_using"           -> ( using.hash, consume.hash )
        //  5. Закінчуємо транзакцію
        ////////////////////////////////////////////////////////

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
        $units   = ( new spr_manager( 'units' )   )->get_raw();
        $recipes = ( new recipes()                )->get_raw();
        $old_data = $this->get_raw( array( 'hash' => array( $reactiv_hash ) ) );

        if( isset($old_data[$reactiv_hash]) )
        {
            $old_data = $old_data[$reactiv_hash];
        }
        else
        {
            $old_data = array();
        }



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
        $SQL['reactiv']['safe_place']      = common::filter( isset($data['safe_place']) ? $data['safe_place'] : false );
        $SQL['reactiv']['safe_needs']      = common::filter( isset($data['safe_needs']) ? $data['safe_needs'] : false );
        $SQL['reactiv']['comment']         = common::filter( isset($data['comment']) ? $data['comment'] : false );
        $SQL['reactiv']['name']            = common::filter( ( $SQL['reactiv']['reactiv_menu_id'] && isset($recipes[$SQL['reactiv']['reactiv_menu_id']]) ) ? $recipes[$SQL['reactiv']['reactiv_menu_id']]['name'] : ( isset($data['name']) ? $data['name'] : false ) );
        $SQL['reactiv']['units_id']        = common::integer( ( $SQL['reactiv']['reactiv_menu_id'] && isset($recipes[$SQL['reactiv']['reactiv_menu_id']]) ) ? $recipes[$SQL['reactiv']['reactiv_menu_id']]['units_id'] : ( isset($data['units_id']) ? $data['units_id'] : false ) );

        // var_export($old_data);exit;

        if( isset($old_data['inc_expert_id']) && common::integer($old_data['inc_expert_id']) != 0 && $old_data['inc_expert_id'] != CURRENT_USER_ID )        { return self::error( 'Вам заборонено редагувати чужі записи!', false ); }

        // if( !$SQL['reactiv']['reactiv_menu_id'] )                                   { return self::error( 'Рецепт приготування не визначено!',              'reactiv_menu_id' ); }

        if( !$SQL['reactiv']['quantity_inc'] )                                      { return self::error( 'Не визначена кількість приготованого реактиву!', 'quantity_inc' ); }
        if( !$SQL['reactiv']['units_id'] )                                          { return self::error( 'Не визначена одиниця виміру!', 'units_id' ); }
        if( strtotime($SQL['reactiv']['inc_date']) > time() )                       { return self::error( 'Дата приготування не може бути з майбутнього!',  'inc_date' ); }
        if( strtotime($SQL['reactiv']['inc_date']) < ( time() - $date_diap ) )      { return self::error( 'Дата приготування занадто давня!',               'inc_date' ); }

        if( strtotime($SQL['reactiv']['dead_date']) < strtotime($SQL['reactiv']['inc_date']) )  { return self::error( 'Дата зберігання не може бути більшою ніж дата приготування!',   'inc_date|dead_date' ); }
        if( strtotime($SQL['reactiv']['dead_date']) > ( time() + $date_diap ) )                 { return self::error( 'Дата зберігання занадто оптимістична! Ця херня стільки не стоятиме!',   'dead_date' ); }

        if( strlen($SQL['reactiv']['safe_place']) > 250 )   { return self::error( 'Місце зберігання занадто довге!',   'safe_place' ); }
        //if( strlen($SQL['reactiv']['safe_place']) < 3 )     { return self::error( 'Місце зберігання занадто коротке!', 'safe_place' ); }

        if( strlen($SQL['reactiv']['safe_needs']) > 250 )   { return self::error( 'Умови зберігання занадто довгі!',   'safe_needs' ); }
        //if( strlen($SQL['reactiv']['safe_needs']) < 3 )     { return self::error( 'Умови зберігання занадто короткі!', 'safe_needs' ); }

        if( strlen($SQL['reactiv']['comment']) > 1000 )     { return self::error( 'Коментар занадто довгий! Це поле не для мемуарів!', 'comment' ); }


        //////////////////////////////////////////////////
        $SQL['consume'] = array();
        $SQL['consume']['reagent'] = array();
        $SQL['consume']['reactiv'] = array();

        if( !is_array($data['composition']) || !count($data['composition']) )
        {
            return self::error( 'Не визначений склад реактиву! Додайте інгрідієнти!' );
        }
        else
        {
            $_comp = array();
            $_comp['reagent'] = array();
            $_comp['reactiv'] = array();

            foreach( $data['composition'] as $ingridient )
            {
                $ingridient = common::filter( $ingridient );

                if( $ingridient['role'] == 'reagent' )
                {                              // consume_hash
                    $SQL['consume']['reagent'][$ingridient['dispersion_id']] = array
                    (
                        'dispersion_id' => common::integer( $ingridient['dispersion_id'] ),
                        'quantity'      => common::float(   $ingridient['quantity'] ),
                        'inc_expert_id' => common::integer( $SQL['reactiv']['inc_expert_id'] ),
                        'date'          => $SQL['reactiv']['inc_date'],
                        'hash'          => isset($ingridient['consume_hash']) ? $ingridient['consume_hash'] : false,
                    );

                    $_comp['reagent'][] = common::integer( $ingridient['reagent_id'] );
                }

                if( $ingridient['role'] == 'reactiv' )
                {
                    $SQL['consume']['reactiv'][$ingridient['reactiv_hash']] = array
                    (
                        'reactiv_hash'  => $this->db->safesql(common::filter_hash( $ingridient['reactiv_hash'] )),
                        'quantity'      => common::float(   $ingridient['quantity'] ),
                        'inc_expert_id' => common::integer( $SQL['reactiv']['inc_expert_id'] ),
                        'date'          => $SQL['reactiv']['inc_date'],
                        'hash'          => isset($ingridient['consume_hash']) ? $ingridient['consume_hash'] : false,
                    );

                    $_comp['reactiv'][] = common::integer( $ingridient['reactiv_menu_id'] );
                }
            }
        }
        //////////////////////////////////////////////////
        //

        foreach( ( $SQL['reactiv']['reactiv_menu_id'] == 0 ? array() : $recipes[$SQL['reactiv']['reactiv_menu_id']]['ingredients_reagent'] ) as $rid => $rdata )
        {
            if( !in_array( $rid, $_comp['reagent'] ) )
            {
                return self::error( 'В Вашому розчині недостатньо інгрідієнтів! Додайте інгрідієнт "'.common::trim( $reagent[$rid]['name'] ).'" згідно рецепту приготування!' );
            }
        }

        foreach( ( $SQL['reactiv']['reactiv_menu_id'] == 0 ? array() : $recipes[$SQL['reactiv']['reactiv_menu_id']]['ingredients_reactiv'] ) as $rid => $rdata )
        {
            if( !in_array( $rid, $_comp['reactiv'] ) )
            {
                return self::error( 'В Вашому розчині недостатньо інгрідієнтів! Додайте інгрідієнт "'.common::trim( $recipes[$rid]['name'] ).'" згідно рецепту приготування!' );
            }
        }
        //
        //////////////////////////////////////////////////

        if( $reactiv_hash && $this->is_used($reactiv_hash) )
        {
            return self::error( 'Даний реактив вже почали використовувати! Редагування заборонено!', 'comment' );
        }

        //////////////////////////////////////////////////

        // STEP 0: BEGIN TRANSACTION
        $this->db->transaction_start();
        ///////////////////////////////

        // STEP 1: INS data to "reactiv"
        $SQL['reactiv']['query'] = !$reactiv_hash
            ?   'INSERT INTO reactiv '.db::array2ins( $SQL['reactiv'] )
            :   'UPDATE reactiv SET '.db::array2upd( $SQL['reactiv'] ).' WHERE hash = \''.$this->db->safesql($reactiv_hash).'\' ';
        $SQL['reactiv']['query'] = $SQL['reactiv']['query'].' RETURNING hash;';

        $SQL['reactiv']['hash'] = $reactiv_hash = $this->db->super_query( $SQL['reactiv']['query'] )['hash'];

        if( !$reactiv_hash )
        {
            $this->db->transaction_rollback();
            return self::error( 'reactiv hash error!' );
        }
        ///////////////////////////////

        // STEP 2: INS data to "consume"
        $consume = new consume;
        $consume_hash = array();
        foreach( $SQL['consume']['reagent'] as $ingridient_id => $ingridient )
        {
            $SQL['consume']['reagent'][$ingridient_id]['hash'] = $consume->save( $ingridient );

            if( $SQL['consume']['reagent'][$ingridient_id]['hash'] )
            {
                $consume_hash[] = $SQL['consume']['reagent'][$ingridient_id]['hash'];
            }
            else
            {
                return false;
            }
        }
        $consume = null;
        unset( $consume );

        if( !$this->update_reactiv_ingr_reagent( $reactiv_hash, $consume_hash ) )
        {
            $this->db->transaction_rollback();
            return self::error( 'update_reactiv_ingr_reagent error!' );
        }
        ///////////////////////////////

        // STEP 3: INS data to "reactiv_consume"
        $reactiv_consume = new reactiv_consume;
        $reactiv_consume_hash = array();
        foreach( $SQL['consume']['reactiv'] as $ingridient_hash => $ingridient )
        {
            $SQL['consume']['reactiv'][$ingridient_hash]['hash'] = $reactiv_consume->save( $ingridient );

            if( $SQL['consume']['reactiv'][$ingridient_hash]['hash'] )
            {
                $reactiv_consume_hash[] = $SQL['consume']['reactiv'][$ingridient_hash]['hash'];
            }
            else
            {
                return false;
            }
        }
        $reactiv_consume = null;
        unset( $reactiv_consume );

        if( !$this->update_reactiv_ingr_reactiv( $reactiv_hash, $reactiv_consume_hash ) )
        {
            return self::error( 'update_reactiv_ingr_reactiv error!' );
        }
        ///////////////////////////////

        // STEP 4: INS data to "using"
        $SQL['using'] = array();
        $SQL['using'] = array_merge( $SQL['using'], $this->db->super_query( 'SELECT DISTINCT ON( "using".hash ) "using".* FROM "using" LEFT JOIN consume_using ON( consume_using.using_hash = "using".hash ) LEFT JOIN reactiv_consume_using ON( reactiv_consume_using.using_hash = "using".hash ) WHERE reactiv_consume_using.consume_hash IN( \'asd\' ) OR consume_using.consume_hash IN( \''.implode('\', \'', $consume_hash).'\' );' ) );

        $SQL['using']['data'] = array
        (
            'purpose_id' => $purpose['id'],
            'group_id' => CURRENT_GROUP_ID,
            'date' => $SQL['reactiv']['inc_date'],
            'hash' => isset($SQL['using']['hash']) ? $SQL['using']['hash'] : false,
        );

        $using = new using;
        $SQL['using']['hash'] = $using->simple_save_using( $SQL['using']['data'] );

        if( !$SQL['using']['hash'] )
        {
            return self::error( 'using hash error!' );
        }

        if( !$using->update_consume_using( $SQL['using']['hash'], $consume_hash ) )
        {
            return self::error( 'update_consume_using error!' );
        }

        if( !$using->update_reactiv_consume_using( $SQL['using']['hash'], $reactiv_consume_hash ) )
        {
            return self::error( 'update_reactiv_consume_using error!' );
        }
        ///////////////////////////////
        $this->db->transaction_commit();
        $this->db->free();

        cache::clean();
        return $SQL['reactiv']['hash'];
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
        $recipes = ( new recipes()                )->get_raw();

        // reactiv & reagent


        $I = 0;
        foreach( $data as $area => $area_data )
        {
            $I = $I + count( $area_data );
        }

        $tpl = new tpl;
        $result = '';
        foreach( $data as $area => $area_data )
        {
            foreach( $area_data as $line )
            {
                $tpl->load( $skin.'_'.$area );

                $tpl->set_block( '!\[(area:'.$area.')\](.+?)\[\/\1\]!is', '$2' );
                $tpl->set_block( '!\[(area:(.+?))\](.+?)\[\/\1\]!is', '' );

                foreach( $_dates as $_date )
                {
                    if( !isset($line[$_date]) ){ continue; }
                    $line[$_date]       = isset($line[$_date]) ? common::en_date( $line[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
                    if( strpos( $line[$_date], '.197' ) !== false ){ $line[$_date] = ''; }
                }

                //////
                $line['numi'] = $I--;
                $line = common::db2html( $line );
                foreach( $line as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:'.$key.'}';

                    $tpl->set( '{tag:'.$key.'}', common::db2html( $value ) );
                }
                //////
                if( isset($line['reagent_id']) && isset($reagent[$line['reagent_id']]) )
                {
                    foreach( $reagent[$line['reagent_id']] as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:reagent:'.$key.'}';
                        $tpl->set( '{tag:reagent:'.$key.'}', common::db2html( $value ) );
                    }

                    foreach( $units[$reagent[$line['reagent_id']]['units_id']] as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:units:'.$key.'}';
                        $tpl->set( '{tag:units:'.$key.'}', common::db2html( $value ) );
                    }
                }
                //////
                if( isset($line['stock_id']) )
                {
                    foreach( (new stock)->get_raw( array( 'id' => $line['stock_id'] ) ) as $stock_data )
                    {
                        if( !$stock_data ){ break; }
                        foreach( $stock_data as $key => $value )
                        {
                            if( is_array($value) ){ continue; }
                            $tags[] = '{tag:stock:'.$key.'}';
                            $tpl->set( '{tag:stock:'.$key.'}', common::db2html( $value ) );
                        }
                    }
                    $stock_data = null;
                    unset( $stock_data );
                }
                //////
                if( isset($line['dispersion_id']) )
                {
                    foreach( (new dispersion)->get_raw( array( 'id' => $line['dispersion_id'] ) ) as $dispersion_data )
                    {
                        if( !$dispersion_data ){ break; }

                        $dispersion_data['inc_date']    = common::en_date( $dispersion_data['inc_date'], 'd.m.Y' );
                        $dispersion_data['dead_date']   = common::en_date( $dispersion_data['dead_date'], 'd.m.Y' );

                        foreach( $dispersion_data as $key => $value )
                        {
                            if( is_array($value) ){ continue; }
                            $tags[] = '{tag:dispersion:'.$key.'}';
                            $tpl->set( '{tag:dispersion:'.$key.'}', common::db2html( $value ) );
                        }
                    }
                    $dispersion_data = null;
                    unset( $dispersion_data );
                }
                //////
                if( isset($line['reactiv_hash']) )
                {
                    $ingridient_data = $this->get_raw( array( 'hash' => $line['reactiv_hash'] ) )[$line['reactiv_hash']];

                    $ingridient_data['inc_date']    = common::en_date( $ingridient_data['inc_date'], 'd.m.Y' );
                    $ingridient_data['dead_date']   = common::en_date( $ingridient_data['dead_date'], 'd.m.Y' );

                    foreach( $ingridient_data as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:reactiv:'.$key.'}';
                        $tpl->set( '{tag:reactiv:'.$key.'}', common::db2html( $value ) );
                    }

                    foreach( $recipes[$ingridient_data['reactiv_menu_id']] as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:menu:'.$key.'}';
                        $tpl->set( '{tag:menu:'.$key.'}', common::db2html( $value ) );
                    }

                    foreach( $units[$recipes[$ingridient_data['reactiv_menu_id']]['units_id']] as $key => $value )
                    {
                        if( is_array($value) ){ continue; }
                        $tags[] = '{tag:units:'.$key.'}';
                        $tpl->set( '{tag:units:'.$key.'}', common::db2html( $value ) );
                    }

                    // var_export($tags);exit;
                }
                //////

                $tpl->compile( $skin.'_'.$area );
            }
            $result = $result . $tpl->result( $skin.'_'.$area );
        }

        return $result;
    }

    public final function editor( $line_hash = false, $skin = false )
    {
        $line_hash = common::filter_hash( $line_hash );
        $data = $this->get_raw( array( 'hash' => $line_hash ) );
        $data = isset( $data[$line_hash] ) ? $data[$line_hash] : false;

        //var_export($data);exit;

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
        $tpl->set( '{ingridients}',
                        $this->get_html( array( 'quantity_left:more' => 0, 'is_dead' => 0 ), 'cooked/ingridient_reactive' )."\n\n".
                        ( new dispersion )->get_html( array( 'quantity_left:more' => 0, 'is_dead' => 0 ), 'cooked/ingridient_reagent' )
        );

        /////////////
        $tpl->set( '{composition}', $this->get_html_composition( $data['composition'], 'cooked/composition' ) );
        /////////////


        $tpl->set( '{autocomplete:table}', 'reactiv' );
        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }



    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        $purpose        = ( new spr_manager( 'purpose' ) )  ->get_raw();
        $units          = ( new spr_manager( 'units' ) )    ->get_raw();
        $reagent        = ( new spr_manager( 'reagent' ) )  ->get_raw();
        $reactiv_menu   = ( new recipes )                   ->get_raw();
        $users          = ( new user )                      ->get_raw( array( 'expert.group_id' => CURRENT_GROUP_ID ) );

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
                $line[$_date.'_unix'] = strtotime( $line[$_date] );
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

                $tpl->set( '{tag:menu:name:lower}', common::strtolower( common::db2html( $reactiv_menu[$line['reactiv_menu_id']]['name'] ) ) );
            }

            if( isset($line['inc_expert_id']) && isset( $users[$line['inc_expert_id']] ) )
            {
                foreach( $users[$line['inc_expert_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:user:'.$key.'}';
                    $tpl->set( '{tag:user:'.$key.'}', common::db2html( $value ) );
                }
                $tpl->set( '{tag:user:name:1}',     common::db2html( substr( $users[$line['inc_expert_id']]['name']     , 0, 1 ) ) );
                $tpl->set( '{tag:user:surname:1}',  common::db2html( substr( $users[$line['inc_expert_id']]['surname']  , 0, 1 ) ) );
                $tpl->set( '{tag:user:phname:1}',   common::db2html( substr( $users[$line['inc_expert_id']]['phname']   , 0, 1 ) ) );
            }

            if( isset( $units[$line['units_id']] ) )
            {
                foreach( $units[$line['units_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:units:'.$key.'}';
                    $tpl->set( '{tag:units:'.$key.'}', common::db2html( $value ) );
                }
            }

            $composition = array();
            foreach( $line['composition'] as $area => $ingridient_list )
            {
                foreach( $ingridient_list as $ingridient )
                {
                    if( isset($ingridient['dispersion_id']) )
                    {
                        $ingridient['dispersion_id'] = common::integer( $ingridient['dispersion_id'] );

                        $_reagent = &$reagent[$ingridient['reagent_id']];
                        $_units   = &$units[$_reagent['units_id']];

                        $composition[] = '  <div class="compos">
                                                <span class="name">'    . common::db2html( $_reagent['name'] ) . ' ['.common::db2html($ingridient['reagent_number']).']:</span>
                                                <span class="quantity">'. common::db2html( $ingridient['consume_quantity'] ).'</span>
                                                <span class="units">'   . common::db2html( $_units['short_name'] ).'</span>
                                            </div>';
                    }
                    else
                    {
                        $_reactiv_menu = &$reactiv_menu[$ingridient['reactiv_menu_id']];
                        $_units   = &$units[$_reactiv_menu['units_id']];

                        $composition[] = '  <div class="compos">
                                                <span class="name">'    . common::db2html( $_reactiv_menu['name'] ) . ':</span>
                                                <span class="quantity">'. common::db2html( $ingridient['consume_quantity'] ).'</span>
                                                <span class="units">'   . common::db2html( $_units['short_name'] ).'</span>
                                            </div>';
                    }
                }
            }

            $tags[]  = '{tag:composition:html}';
            $tpl->set( '{tag:composition:html}', implode( '', $composition ) );

            $tpl->compile( $skin );
        }


        //var_export($tags);
        return $tpl->result( $skin );
    }


    public final function get_raw( $filters = array() )
    {
        $WHERE = array();

        $WHERE['reactiv.hash'] = 'reactiv.hash != \'\'';
        $WHERE['reactiv.group_id'] = '( reactiv.group_id = \''.CURRENT_GROUP_ID.'\'::INTEGER OR reactiv.group_id = 0 )';

        if( is_array($filters) )
        {
            if( isset($filters['quantity_left:more']) )
            {
                $filters['quantity_left:more'] = common::float($filters['quantity_left:more']);
                $WHERE['reactiv.quantity_left']   = 'reactiv.quantity_left > \''. $filters['quantity_left:more'] .'\'::float';
            }

            if( isset($filters['quantity_left']) )
            {
                $filters['quantity_left'] = common::float($filters['quantity_left']);
                $WHERE['reactiv.quantity_left']   = 'reactiv.quantity_left = \''. $filters['quantity_left'] .'\'::float';
            }

            if( isset($filters['is_dead']) )
            {
                $filters['is_dead'] = common::integer($filters['is_dead']);
                $WHERE['reactiv.dead_date']   = 'reactiv.dead_date ' . ( $filters['is_dead'] ? ' < ' : ' >= ' ) . ' NOW()::date';
            }

            if( isset($filters['hash']) )
            {
                $filters['hash'] = common::filter_hash( $filters['hash'] );
                $filters['hash'] = is_array($filters['hash']) ? $filters['hash'] : array( $filters['hash'] );

                if( count($filters['hash']) )
                {
                    $WHERE['reactiv.hash']   = 'reactiv.hash IN (\''.implode( '\', \'', $filters['hash'] ).'\')';
                }
            }

        }

        //

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        $SQL = '
            SELECT
                reactiv.*,
                reactiv.name as reactiv_menu_name,
                units.name as units_name,
                units.short_name as units_short_name
            FROM
                reactiv
                LEFT JOIN units ON( units.id = reactiv.units_id )
            '.$WHERE.'
            ORDER by
                reactiv.inc_date DESC,
                reactiv.name ASC;

            '.db::CACHED;

        //echo $SQL;exit;

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
            $data[$row['hash']]['composition']['reagent'] = array();
            $data[$row['hash']]['composition']['reactiv'] = array();
            $data[$row['hash']]['using_hash'] = false;
        }

        //////////////////////////////////////////////////////////////////////////////////
        if( is_array($data) && count($data) )
        {
            // ВИБРАТИ ІНГРІДІЄНТИ (РЕЧОВИНИ) //
            $SQL = '
                SELECT
                    reactiv_ingr_reagent.reactiv_hash 	as hash,
                    consume.hash 						as consume_hash,
                    "using".hash 						as using_hash,
                    consume.quantity	                as consume_quantity,
                    dispersion.id					    as dispersion_id,
                    stock.id						    as stock_id,
                    stock.reagent_id				    as reagent_id,
                    stock.reagent_number			    as reagent_number
                FROM
                    reactiv_ingr_reagent
                    LEFT JOIN consume ON( consume.hash = reactiv_ingr_reagent.consume_hash )
                    LEFT JOIN dispersion ON( consume.dispersion_id = dispersion.id )
                    LEFT JOIN stock ON( stock.id = dispersion.stock_id )
                    LEFT JOIN consume_using ON( consume_using.consume_hash = consume.hash )
                    LEFT JOIN "using" ON( "using".hash = consume_using.using_hash )
                WHERE
                    reactiv_ingr_reagent.reactiv_hash IN( \''.implode( '\', \'', array_keys($data) ).'\' )
                    AND  dispersion.group_id    = \''.CURRENT_GROUP_ID.'\'::INTEGER
                    AND "using".group_id        = \''.CURRENT_GROUP_ID.'\'::INTEGER
            ';


            $SQL = $this->db->query( $SQL );

            while( ( $row = $this->db->get_row( $SQL ) ) !== false )
            {
                //var_export($row);exit;

                $data[$row['hash']]['composition']['reagent'][$row['reagent_id']] = $row;

                if( !isset($data[$row['hash']]['using_hash']) || !$data[$row['hash']]['using_hash'] ){ $data[$row['hash']]['using_hash'] = $row['using_hash']; }
                if( $data[$row['hash']]['using_hash'] != $row['using_hash'] )
                {
                    return self::error( 'Problems with "using_hash"! Hash is different at one reactive!' );
                }
            }

            // ВИБРАТИ ІНГРІДІЄНТИ (РОЗЧИНИ) //
            $SQL = '
                SELECT
                    reactiv_ingr_reactiv.reactiv_hash 	    as hash,
                    reactiv_consume.hash 	        as consume_hash,
                    reactiv_consume.quantity 		as consume_quantity,
                    reactiv.hash			        as reactiv_hash,
                    "using".hash			        as using_hash,
                    reactiv.reactiv_menu_id         as reactiv_menu_id
                FROM
                    reactiv_ingr_reactiv
                    LEFT JOIN reactiv_consume ON( reactiv_consume.hash = reactiv_ingr_reactiv.consume_hash )
                    LEFT JOIN reactiv 		  ON( reactiv.hash = reactiv_consume.reactiv_hash )

                    LEFT JOIN reactiv_consume_using ON( reactiv_consume_using.consume_hash = reactiv_consume.hash )
                    LEFT JOIN "using" ON( "using".hash = reactiv_consume_using.using_hash )
                WHERE
                    reactiv_ingr_reactiv.reactiv_hash IN( \''.implode( '\', \'', array_keys($data) ).'\' )
                    AND  reactiv.group_id = \''.CURRENT_GROUP_ID.'\'::INTEGER
                    AND "using".group_id  = \''.CURRENT_GROUP_ID.'\'::INTEGER
                ;
            ';

            $SQL = $this->db->query( $SQL );

            while( ( $row = $this->db->get_row( $SQL ) ) !== false )
            {

                $data[$row['hash']]['composition']['reactiv'][$row['reactiv_hash']] = $row;

                if( !isset($data[$row['hash']]['using_hash']) || !$data[$row['hash']]['using_hash'] ){ $data[$row['hash']]['using_hash'] = $row['using_hash']; }
                if( $data[$row['hash']]['using_hash'] != $row['using_hash'] )
                {
                    return self::error( 'Problems with "using_hash"! Hash is different at one reactive!' );
                }
            }

            // ВИБРАТИ ХЕШ-СУМИ ВИКОРИСТАННЯ //

        }
        //////////////////////////////////////////////////////////////////////////////////

        cache::set( $cache_var, $data );
        return $data;
    }

}