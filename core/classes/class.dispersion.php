<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class dispersion
{
    use basic, spr, db_connect;

    public final function remove( $ID = 0 )
    {
        access::check( 'dispersion', 'edit' );

        $ID = common::integer( $ID );
        $error = '';

        if( !$error && !$ID ){ $error = 'Ідентифікатор не визначено!'; }

        ////////////////////////////////////

        $data = array();
        if( !$error && $ID ){ $data = $ID?$this->get_raw(array('id'=>$ID))[$ID] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) )                                  { $error = 'Помилка отримання даних!'; }
        if( !$error && common::strtotime( $data['created_ts'] ) < ( time() - (60*60*24*14) ) )  { $error = 'Заборонено видаляти записи, створені пізні ніж 14 днів тому!'; }
        if( !$error && $data['quantity_left'] != $data['quantity_inc'] )                        { $error = 'Неможливо видалити реактив, який вже почали використовувати!';  }

        ////////////////////////////////////

        if( $error != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), $error ); return false; }
            else        { common::err( $error ); return false; }
        }

        $SQL = 'DELETE FROM dispersion WHERE id='.$ID.' AND group_id='.CURRENT_GROUP_ID.';';
        $this->db->query( $SQL );

        cache::clean( 'spr-dispersion' );
        cache::clean( 'spr' );
        cache::clean();

        return $ID;
    }

    static public final function check_data_before_save( $data4save = array(), $original_data = array() )
    {
        if( !is_array($data4save) ){ return false; }
        if( !is_array($original_data) ){ return false; }

        $fucktime_years     = 1;
        $fucktime_period    = 60*60*24*365*$fucktime_years;
        $fucktime_ago       = time() - $fucktime_period;
        $fucktime_farevey   = time() + $fucktime_period;

        $ID = common::integer( isset($original_data['id']) ? $original_data['id'] : false );

        $error = false;
        $error_area = false;

        ///////////

        if( !$error && $ID && $data4save['group_id']  != $original_data['group_id'] )       { $error = 'Ви не можете редагувати записи з іншого відділу!'; $error_area = ''; }
        if( !$error && $ID && $data4save['stock_id']  != $original_data['stock_id'] )       { $error = 'Заборонено редагувати реагент!'; $error_area = 'stock_id'; }
        if( !$error && $ID && !$data4save['stock_id'] )                                     { $error = 'Вкажіть реагент!'; $error_area = 'stock_id'; }

        ///////////

        $_date_areas = array( 'inc_date' );

        foreach( $_date_areas as $_date_area )
        {
            $data4save[$_date_area]      = common::strtotime($data4save[$_date_area]);

            if( !$error && $data4save[$_date_area] > $fucktime_farevey ){ $error = 'Дата "'.$_date_area.'" більша за дозволений проміжок часу (+'.$fucktime_years.' років)!'; $error_area = $_date_area; }
            if( !$error && $data4save[$_date_area] < $fucktime_ago )    { $error = 'Дата "'.$_date_area.'" менша за дозволений проміжок часу (-'.$fucktime_years.' років)!';  $error_area = $_date_area; }
            if( $error ){ break; }
        }

        if( !$error && $data4save['inc_date'] >= time() )                        { $error = 'Перевірте дату видачі!'; $error_area = 'inc_date'; }

        ///////////

        if( !$error && $data4save['quantity_inc'] == 0 )      { $error = 'Зазначте кількість реактиву!'; $error_area = 'quantity_inc'; }
        if( !$error && $data4save['out_expert_id'] == 0 )     { $error = 'Зазначте хто отримав реактив!'; $error_area = 'out_expert_id'; }



        ///////////
        $stock = ( new stock )->get_raw( array( 'id' => $data4save['stock_id'] ) )[$data4save['stock_id']];

        if( !$error && ( ( $stock['quantity_left'] + (isset($original_data['quantity_inc'])?$original_data['quantity_inc']:0) ) - $data4save['quantity_inc'] ) < 0 )
        {
            $error = 'Ви намагаєтесь видати задагато теактиву! Вирахувати недостачу з Вашої заробітної плати?'; $error_area = 'quantity_inc';
        }

        if( time() > strtotime($stock['dead_date']) ){ $error = 'Ви намагаєтесь видати зіпсований реактив!'; $error_area = 'stock_id'; }

        ///////////

        if( $error != false )
        {
            if( _AJAX_ )
            {
                ajax::set_error( rand(10,99), $error );
                ajax::set_data( 'err_area', $error_area );
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

    public final function save( $ID = 0, $data = array() )
    {
        access::check( 'dispersion', 'edit' );

        $ID = common::integer( $ID );

        if( !is_array($data) ){ return false; }

        $SQL = array();

        $SQL['inc_expert_id']       = CURRENT_USER_ID;
        $SQL['group_id']            = CURRENT_GROUP_ID;
        $SQL['stock_id']            = common::integer($data['stock_id']);
        $SQL['out_expert_id']       = common::integer($data['out_expert_id']);
        $SQL['quantity_inc']        = common::float($data['quantity_inc']);
        $SQL['inc_date']            = common::en_date($data['inc_date'] ,'Y-m-d');
        $SQL['comment']             = common::filter($data['comment']);

        foreach( $SQL as $k => $v )
        {
            $SQL[$k] = $this->db->safesql( $v );
        }

        ///////////////////////////////////////////////////

        if( !self::check_data_before_save( $SQL, $ID?$this->get_raw(array('id'=>$ID))[$ID] : array() ) ){ return false; }

        ///////////////////////////////////////////////////

        if( $ID > 0 )
        {
            foreach( $SQL as $k => $v ){ $SQL[$k] =  '"'.$k.'"= \''.$v.'\''; }
            $SQL = 'UPDATE dispersion SET '.implode( ', ', $SQL ).' WHERE id = '.$ID.' RETURNING id;';
        }
        else
        {
            $SQL = 'INSERT INTO dispersion ("'.implode('", "', array_keys($SQL) ).'") VALUES ( \''.implode('\', \'', array_values($SQL)).'\' ) RETURNING id;';
        }

        $this->db->query( 'BEGIN;' );
        $ID = $this->db->super_query( $SQL );

        $ID = isset($ID['id']) ? $ID['id'] : false;

        if( $ID ){ $this->db->query( 'COMMIT;' ); }
             else{ $this->db->query( 'ROLLBACK;' ); }

        cache::clean( 'spr-dispersion' );
        cache::clean( 'spr' );
        cache::clean();

        return $ID;
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );

        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $units   = ( new spr_manager( 'units' )   )->get_raw();

        $data = is_array($data) ? $data : array();

        $tpl = new tpl;

        $I = count( $data );

        foreach( $data as $line )
        {
            $tpl->load( $skin );

            $line['not_used_perc'] = common::compare_perc( $line['quantity_inc'], $line['quantity_left'] );

            if( $line['not_used_perc'] <= 1 )                                { $tpl->set(  '{tag:not_used_class}',  'fully_used' );     }
            if( $line['not_used_perc'] >  1 && $line['not_used_perc'] <= 10 ){ $tpl->set( '{tag:not_used_class}',   'almost_used' );    }
            if( $line['not_used_perc'] > 10 && $line['not_used_perc'] <= 50 ){ $tpl->set( '{tag:not_used_class}',   'half_used' );      }
            if( $line['not_used_perc'] > 50 )                                { $tpl->set( '{tag:not_used_class}',  'not_used' );        }

            $line['lifetime'] = strtotime( $line['dead_date'] ) - time();
            if( $line['lifetime'] < 0 )
            {
                $line['lifetime'] = 'gone';
            }
            else
            {
                $line['lifetime'] = floor( $line['lifetime'] / ( 60*60*24 ) );
            }



            $line['numi'] = $I--;

            $line['inc_date_unix']  = strtotime( $line['inc_date'] );
            $line['dead_date_unix'] = strtotime( $line['dead_date'] );
            $line['inc_date'] = date( 'd.m.Y', $line['inc_date_unix'] );

            $line['dead_date'] = date( 'd.m.Y', strtotime( $line['dead_date'] ) );

            $line['reagent_number_separete'] = explode( '-', $line['reagent_number'] );
            $line['reagent_number_separete'] = common::integer( $line['reagent_number_separete'] );

            $tpl->set( '{tag:reagent_number:0}', common::db2html( str_repeat( '0', 5-strlen($line['reagent_number_separete'][0]) ) ).$line['reagent_number_separete'][0] );
            $tpl->set( '{tag:reagent_number:1}', common::db2html( $line['reagent_number_separete'][1] ) );

            $line = common::db2html( $line );

            foreach( $line as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tpl->set( '{tag:'.$key.'}', $value );
            }

            foreach( ( isset($reagent[$line['reagent_id']]) ? $reagent[$line['reagent_id']] : array() ) as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tpl->set( '{tag:reagent:'.$key.'}', $value );
            }

            foreach( ( ( isset($reagent[$line['reagent_id']]) && isset($units[$reagent[$line['reagent_id']]['units_id']]) ) ? $units[$reagent[$line['reagent_id']]['units_id']] : array() ) as $key => $value )
            {
                if( is_array($value) ){ continue; }
                $tpl->set( '{tag:reagent:units:'.$key.'}', $value );
            }

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function editor( $line_id = 0, $skin = false )
    {
        access::check( 'dispersion', 'view' );

        $line_id = common::integer( $line_id );

        $data = $this->get_raw( array( 'id' => $line_id ) );
        $data = isset( $data[$line_id] ) ? $data[$line_id] : false;

        if( !is_array($data) ){ return false; }

        $_dates = array();
        $_dates[] = 'inc_date';

        foreach( $_dates as $_date )
        {
            $data[$_date]       = isset($data[$_date])      ? common::en_date( $data[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
            if( strpos( $data[$_date], '.197' ) !== false ){ $data[$_date] = ''; }
        }

        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_id );

        //var_export($data);exit;

        ////////////
        $data['inc_expert_id'] = common::integer( $data['inc_expert_id'] );
        $inc_expert = $data['inc_expert_id']?$data['inc_expert_id']:CURRENT_USER_ID;
        $user = new user;
        $user = $user->get_user_data_raw( $inc_expert )[$inc_expert];
        $data['inc_expert_name'] = $user['name'];
        $data['inc_expert_phname'] = $user['phname'];
        $data['inc_expert_surname'] = $user['surname'];
        ////////////
        //$data['out_expert_id'] = common::integer( $data['out_expert_id'] );
        //$inc_expert = $data['out_expert_id']?$data['out_expert_id']:CURRENT_USER_ID;
        //$user = new user;
        //$user = $user->get_user_data_raw( $inc_expert )[$inc_expert];
        //$data['out_expert_name'] = $user['name'];
        //$data['out_expert_phname'] = $user['phname'];
        //$data['out_expert_surname'] = $user['surname'];
        ////////////

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
        }

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {

        $WHERE = array();
        $WHERE['dispersion.group_id'] = '( dispersion.group_id = \''.CURRENT_GROUP_ID.'\'::INTEGER OR dispersion.group_id = 0 )';

        if( is_array($filters) )
        {
            if( isset($filters['id']) )
            {
                $filters['id'] = common::integer( $filters['id'] );
                $WHERE['dispersion.id'] = 'dispersion.id = '.$filters['id'].'';
            }
            else
            {
                $WHERE['dispersion.id'] = 'dispersion.id > 0';
            }

            if( isset($filters['quantity_left:more']) )
            {
                $filters['quantity_left:more'] = common::float( $filters['quantity_left:more'] );
                $WHERE['quantity_left:more'] = ' dispersion.quantity_left > \''.$filters['quantity_left:more'].'\'::FLOAT';
            }

            if( isset($filters['quantity_left:less']) )
            {
                $filters['quantity_left:less'] = common::float( $filters['quantity_left:less'] );
                $WHERE['quantity_left:less'] = ' dispersion.quantity_left < \''.$filters['quantity_left:less'].'\'::FLOAT';
            }

            if( isset($filters['quantity_left:is']) )
            {
                $filters['quantity_left:is'] = common::float( $filters['quantity_left:is'] );
                $WHERE['quantity_left:is'] = ' dispersion.quantity_left = \''.$filters['quantity_left:is'].'\'::FLOAT';
            }
        }

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        $SQL = '
            SELECT
                dispersion.*,
                groups.region_id,
                reagent.id   as reagent_id,
                stock.reagent_number,
                stock.dead_date,
                units.name   as reagent_units,
                units.short_name   as reagent_units_short,

                out_expert.name as out_expert_name,
                out_expert.phname as out_expert_phname,
                out_expert.surname as out_expert_surname,

                inc_expert.name as inc_expert_name,
                inc_expert.phname as inc_expert_phname,
                inc_expert.surname as inc_expert_surname

            FROM
                dispersion
                    LEFT JOIN stock     ON( dispersion.stock_id = stock.id AND dispersion.group_id = stock.group_id )
                    LEFT JOIN reagent   ON( reagent.id = stock.reagent_id )
                    LEFT JOIN units     ON ( units.id = reagent.units_id )
                    LEFT JOIN expert  as out_expert ON( out_expert.id = dispersion.out_expert_id )
                    LEFT JOIN expert  as inc_expert ON( inc_expert.id = dispersion.inc_expert_id )
                    LEFT JOIN groups    ON ( dispersion.group_id = groups.id )

            '.$WHERE.'

            ORDER by
                reagent.name ASC; '.db::CACHED;

        $cache_var = 'spr-dispersion-'.md5( $SQL ).'-raw';

        $data = cache::get( $cache_var );

        if( $data && is_array($data) ){ return $data; }

        $data = array();
        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::clean( $cache_var );

        cache::set( $cache_var, $data );
        return $data;
    }
}