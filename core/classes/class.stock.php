<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class stock
{
    use basic, spr, db_connect;

    static public final function check_data_before_save( $data4save = array(), $original_data = array() )
    {
        if( !is_array($data4save) ){ return false; }
        if( !is_array($original_data) ){ return false; }

        $fucktime_years     = 10;
        $fucktime_period    = 60*60*24*365*$fucktime_years;
        $fucktime_ago       = time() - $fucktime_period;
        $fucktime_farevey   = time() + $fucktime_period;

        $ID = common::integer( isset($original_data['id']) ? $original_data['id'] : false );

        $error = false;
        $error_area = false;

        ///////////

        if( !$error && $ID &&  $data4save['region_id']  != $original_data['region_id'] )      { $error = '�� �� ������ ���������� ������ � ������ ������!'; $error_area = ''; }
        if( !$error && $ID &&  $data4save['group_id']   != $original_data['group_id'] )       { $error = '�� �� ������ ���������� ������ � ������ �����!'; $error_area = ''; }
        if( !$error && $ID &&  $data4save['reagent_id'] != $original_data['reagent_id'] )    { $error = '���������� ���������� �������!'; $error_area = 'reagent_id'; }
        if( !$error && $ID && !$data4save['reagent_id'] )                                   { $error = '������ �������!'; $error_area = 'reagent_id'; }

        ///////////

        $_date_areas = array( 'inc_date', 'create_date', 'dead_date' );

        foreach( $_date_areas as $_date_area )
        {
            $data4save[$_date_area]      = common::strtotime($data4save[$_date_area]);

            if( !$error && $data4save[$_date_area] > $fucktime_farevey ){ $error = '���� "'.$_date_area.'" ����� �� ���������� ������� ���� (+'.$fucktime_years.' ����)!'; $error_area = $_date_area; }
            if( !$error && $data4save[$_date_area] < $fucktime_ago )    { $error = '���� "'.$_date_area.'" ����� �� ���������� ������� ���� (-'.$fucktime_years.' ����)!';  $error_area = $_date_area; }
            if( $error ){ break; }
        }

        if( !$error && $data4save['inc_date'] >= $data4save['dead_date'] )       { $error = '����� ���������� �������� ��������?'; $error_area = 'inc_date|dead_date'; }
        if( !$error && $data4save['inc_date'] >= time() )                        { $error = '�������� ���� �����������!'; $error_area = 'inc_date'; }
        if( !$error && $data4save['create_date'] >= time() )                     { $error = '�������� ���� ������������!'; $error_area = 'create_date'; }
        if( !$error && $data4save['create_date'] >= $data4save['dead_date'] )    { $error = '������� ��������� ������, ��� ���� ����������?'; $error_area = 'create_date|dead_date'; }
        if( !$error && $data4save['create_date'] > $data4save['inc_date'] )      { $error = '������� � �����������? �������� ���� ������������ �� ���� �����������!'; $error_area = 'create_date|inc_date'; }

        ///////////

        if( !$error && $data4save['quantity_inc'] == 0 )      { $error = '�������� ������� ��������!'; $error_area = 'quantity_inc'; }
        if( !$error && $data4save['clearence_id'] == 0 )      { $error = '�������� ������� ��������!'; $error_area = 'clearence_id'; }
        if( !$error && $data4save['reagent_state_id'] == 0 )  { $error = '�������� ����� ����������� ��������!'; $error_area = 'reagent_state_id'; }
        if( !$error && $data4save['danger_class_id'] == 0 )   { $error = '�������� ���� ��������� ��������!'; $error_area = 'danger_class_id'; }

        ///////////

        if( !$error && common::strlen($data4save['creator']) <= 3 )      { $error = '�������� ���������!'; $error_area = 'creator'; }
        if( !$error && common::strlen($data4save['creator']) >= 250 )    { $error = '����� ��������� ������� �����! �� 250 ������� ���� �����!'; $error_area = 'creator'; }

        if( !$error && common::strlen($data4save['safe_place']) <= 3 )      { $error = '�������� ���� ���������!'; $error_area = 'safe_place'; }
        if( !$error && common::strlen($data4save['safe_place']) >= 250 )    { $error = '̳��� ��������� ������� �����! �� 250 ������� ���� �����!'; $error_area = 'safe_place'; }

        if( !$error && common::strlen($data4save['safe_needs']) <= 3 )      { $error = '�������� ����� ���������!'; $error_area = 'safe_needs'; }
        if( !$error && common::strlen($data4save['safe_needs']) >= 250 )    { $error = '����� ��������� ������� ����! �� 250 ������� ���� �����!'; $error_area = 'safe_needs'; }

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

    public final function remove( $ID = 0 )
    {
        $ID = common::integer( $ID );
        $error = '';

        if( !$error && !$ID ){ $error = '������������� �� ���������!'; }

        ////////////////////////////////////

        $data = array();
        if( !$error && $ID ){ $data = $ID?$this->get_raw(array('id'=>$ID))[$ID] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) )                                  { $error = '������� ��������� �����!'; }
        if( !$error && common::strtotime( $data['created_ts'] ) < ( time() - (60*60*24*14) ) )  { $error = '���������� �������� ������, �������� ���� ��� 14 ���� ����!'; }
        if( !$error && $data['quantity_left'] != $data['quantity_inc'] )                        { $error = '��������� �������� �������, ���� ��� ������� � ����������!';  }

        ////////////////////////////////////

        if( $error != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), $error ); return false; }
            else        { common::err( $error ); return false; }
        }

        $SQL = 'DELETE FROM stock WHERE id='.$ID.' AND region_id='.CURRENT_REGION_ID.' AND group_id='.CURRENT_GROUP_ID.';';
        $this->db->query( $SQL );

        cache::clean();

        return $ID;
    }

    public final function save( $ID = 0, $data = array() )
    {
        $ID = common::integer( $ID );

        if( !is_array($data) ){ return false; }

        $SQL = array();

        $SQL['region_id']           = CURRENT_REGION_ID;
        $SQL['inc_expert_id']       = CURRENT_USER_ID;
        $SQL['group_id']            = CURRENT_GROUP_ID;
        $SQL['reagent_id']          = common::integer($data['reagent_id']);
        $SQL['reagent_state_id']    = common::integer($data['reagent_state_id']);
        $SQL['clearence_id']        = common::integer($data['clearence_id']);
        $SQL['is_sertificat']       = common::integer($data['is_sertificat']);
        $SQL['is_suitability']      = common::integer($data['is_suitability']);
        $SQL['danger_class_id']     = common::integer($data['danger_class_id']);

        $SQL['quantity_inc']        = common::float($data['quantity_inc']);

        $SQL['inc_date']            = common::en_date($data['inc_date']     ,'Y-m-d');
        $SQL['create_date']         = common::en_date($data['create_date']  ,'Y-m-d');
        $SQL['dead_date']           = common::en_date($data['dead_date']    ,'Y-m-d');

        $SQL['creator']             = common::filter($data['creator']);
        $SQL['safe_needs']          = common::filter($data['safe_needs']);
        $SQL['safe_place']          = common::filter($data['safe_place']);
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
            $SQL = 'UPDATE stock SET '.implode( ', ', $SQL ).' WHERE id = '.$ID.' RETURNING id;';
        }
        else
        {
            $SQL = 'INSERT INTO stock ("'.implode('", "', array_keys($SQL) ).'") VALUES ( \''.implode('\', \'', array_values($SQL)).'\' ) RETURNING id;';
        }

        $this->db->query( 'BEGIN;' );
        $ID = $this->db->super_query( $SQL );

        $ID = isset($ID['id']) ? $ID['id'] : false;

        if( $ID ){ $this->db->query( 'COMMIT;' ); }
             else{ $this->db->query( 'ROLLBACK;' ); }

        cache::clean();

        return $ID;
    }

    public final function editor( $line_id = 0, $skin = false )
    {
        $line_id = common::integer( $line_id );

        $data = $this->get_raw( array( 'id' => $line_id ) );
        $data = isset( $data[$line_id] ) ? $data[$line_id] : false;

        if( !is_array($data) ){ return false; }

        $_dates = array();
        $_dates[] = 'inc_date';
        $_dates[] = 'create_date';
        $_dates[] = 'dead_date';

        foreach( $_dates as $_date )
        {
            $data[$_date]       = isset($data[$_date])      ? common::en_date( $data[$_date], 'd.m.Y' ) : date( 'd.m.Y' );
            if( strpos( $data[$_date], '.197' ) !== false ){ $data[$_date] = ''; }
        }

        $data['quantity_inc'] = common::float( $data['quantity_inc'] );

        if( $data['quantity_inc'] == 0 ){ $data['quantity_inc'] = ''; }

        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_id );

        if( !$data['expert_name'] || !$data['expert_phname'] || !$data['expert_surname'] )
        {
            $user = new user;
            $user = $user->get_user_data_raw( CURRENT_USER_ID )[CURRENT_USER_ID];

            $data['expert_name'] = $user['name'];
            $data['expert_phname'] = $user['phname'];
            $data['expert_surname'] = $user['surname'];
        }

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            $tpl->set( '{autocomplete:'.$k.':key}', autocomplete::key( 'stock', $k ) );
        }

        $tpl->set( '{autocomplete:table}', 'stock' );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );


            $line['numi'] = $I--;

            $line['inc_date_unix'] = strtotime( $line['inc_date'] );
            $line['inc_date'] = date( 'Y.m.d', $line['inc_date_unix'] );

            $line['quantity_used'] = common::float( $line['quantity_dispersed'] ) - common::float( $line['quantity_not_used'] );

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

    static public final function get_select( $selected_id = 0 )
    {
        $class = new self;

        $data = $class->get_raw();
        $data = is_array($data) ? $data : array();

        foreach( $data as $k=>$line )
        {
            $line['reagent_units_1l'] = substr($line['reagent_units'],0,1);
            $line = common::db2html( $line );

            $data[$k] = array();
            foreach( $line as $key => $val )
            {
                $data[$k][] = 'data-'.$key.'="'.$val.'"';
            }
            $data[$k] = '<option title="'.$line['reagent_name'].'" value="'.$line['id'].'" '.implode( ' ', $data[$k] ).'>'.$line['reagent_name'].' [��������: '.$line['quantity_left'].' '.$line['reagent_units_short'].']</option>';
        }
        $data = "\n\t".implode( "\n\t", $data )."\n";

        return $data;
    }

    public final function get_raw( $filters = array() )
    {

        if( is_array($filters) )
        {
            if( isset($filters['id']) ){ $filters['id'] = common::integer( $filters['id'] ); }
        }

        $SQL = '
            SELECT
                stock.*,
                reagent.name    as reagent_name,
                units.name      as reagent_units,
                units.short_name   as reagent_units_short,

                expert.name     as expert_name,
                expert.surname as expert_surname,
                expert.phname as expert_phname,
                COALESCE( (SELECT SUM(dispersion.quantity_inc)  FROM dispersion WHERE dispersion.stock_id = stock.id), 0 ) as quantity_dispersed,
                COALESCE( (SELECT SUM(dispersion.quantity_left) FROM dispersion WHERE dispersion.stock_id = stock.id), 0 ) as quantity_not_used
            FROM
                stock
                LEFT JOIN reagent   ON ( reagent.id = stock.reagent_id )
                LEFT JOIN units     ON ( units.id = reagent.units_id )
                LEFT JOIN expert    ON  ( expert.id = stock.inc_expert_id )
            WHERE
                '.(isset($filters['id'])?'stock.id = \''.$filters['id'].'\'::INTEGER':'stock.id > 0').'
                '.(( isset($filters['id']) && $filters['id'] == 0 )?'':'AND stock.region_id = '.CURRENT_REGION_ID.'').'
                '.(( isset($filters['id']) && $filters['id'] == 0 )?'':(CURRENT_GROUP_ID?'AND stock.group_id = \''.CURRENT_GROUP_ID.'\'::INTEGER ':'')).'
            ORDER by
                stock.inc_date DESC; '.db::CACHED;

        $cache_var = 'stock-'.md5($SQL).'-raw';
        $data = cache::get( $cache_var );
        $data = false;
        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );
        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        cache::set( $cache_var, $data );
        return $data;
    }
}