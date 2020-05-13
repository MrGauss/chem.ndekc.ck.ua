<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class spr_manager
{
    use basic, spr, db_connect;

    const CACHE_CONST = 'spr';

    private $table = false;
    private $table_info = array();

    public static $_spr = array
                            (
                                'danger_class',
                                'reagent_state',
                                'clearence',
                                'region',
                                'reagent',
                                'purpose',
                                'units',
                            );

    public static $_columns_not_allowed_to_save =
                            array
                            (
                                'id',
                                'ts',
                            );

    public final function __construct( $table )
    {
        $this->__cconnect_2_db();

        $this->table = false;
        if( in_array( $table, self::$_spr ) )
        {
            $this->table = $table;
            $this->table_info = $this->get_table_info();
        }
    }


    public final function editor( $line_id = 0, $skin = false )
    {
        access::check( 'spr', 'edit' );

        $line_id = common::integer( $line_id );

        cache::clean( self::CACHE_CONST.'-'.$this->table );

        $data = $this->get_raw( array( 'id' => $line_id ) );
        $data = isset( $data[$line_id] ) ? $data[$line_id] : false;

        if( !is_array($data) ){ return false; }

        if( isset($data['attr']) && $data['attr'] != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), 'Даний запис є службовим та не редагується!' ); return false; }
            else        { common::err( 'Даний запис є службовим та не редагується!' ); return false; }
        }

        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_id );

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
            $tpl->set( '{autocomplete:'.$k.':key}', autocomplete::key( $this->table, $k ) );
        }

        $tpl->set( '{autocomplete:table}', $this->table );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        if( !$this->table ){ common::err( 'Не зазначена таблиця довідника!' ); };

        $data = $this->get_raw( $filters );

        $data = is_array($data) ? $data : array();

        $tpl = new tpl;

        $I = count( $data );
        foreach( $data as $line )
        {
            $tpl->load( $skin );


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

    public static final function make_select( $table, $selected = 0 )
    {
        $spr = new self( $table );
        return $spr->get_select();
    }

    public final function get_select( $filters = array() )
    {
        if( !$this->table ){ common::err( 'Не зазначена таблиця довідника!' ); };

        $data = $this->get_raw( $filters );



        if( !is_array($data) ){ return ''; }

        foreach( $data as $id => $line )
        {
            $line = common::db2html($line);
            $attr = array();

            foreach( $line as $k => $v ){ $attr[] = 'data-'.$k.'="'.$v.'"'; }

            $attr = implode( ' ', $attr );

            $data[$id] = '<option '.$attr.' value="'.$id.'">'.$line['name'].'</option>';
        }
        return implode( '', $data );
    }

    public final function remove( $ID = 0 )
    {
        access::check( 'spr', 'edit' );

        if( !$this->table ){ common::err( 'Не зазначена таблиця довідника!' ); };

        $ID = common::integer( $ID );
        $error = '';

        if( !$error && !$ID ){ $error = 'Ідентифікатор не визначено!'; }

        ////////////////////////////////////
        $data = array();
        if( !$error && $ID ){ $data = $ID?$this->get_raw(array('id'=>$ID))[$ID] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) ){ $error = 'Помилка отримання даних!'; }
        if( $this->check_usage( $ID ) ){ $error = 'Запис використовується! В видаленні відмовлено!'; }

        ////////////////////////////////////

        if( $error != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), $error ); return false; }
            else        { common::err( $error ); return false; }
        }

        if( !$error )
        {
            $SQL = 'DELETE FROM '.$this->table.' WHERE id='.$ID.';';
            $this->db->query( $SQL );
        }

        cache::clean();

        return $ID;
    }

    public final function check_data_before_save( $data4save = array(), $original_data = array() )
    {
        if( !is_array($data4save) ){ return false; }
        if( !is_array($original_data) ){ return false; }

        $ID = common::integer( isset($original_data['id']) ? $original_data['id'] : false );

        $error = false;
        $error_area = false;

        ///////////
        if( !$error && isset($data4save['name']) && common::strlen( $data4save['name'] ) > 64 )     { $error = 'Назва занадто довга!'; $error_area = 'name'; }
        if( !$error && isset($data4save['name']) && common::strlen( $data4save['name'] ) < 3 )      { $error = 'Назва занадто коротка!'; $error_area = 'name'; }

        if( !$error && isset($data4save['full_name']) && common::strlen( $data4save['full_name'] ) > 250 )    { $error = 'Повна назва занадто довга!'; $error_area = 'full_name'; }
        if( !$error && isset($data4save['full_name']) && common::strlen( $data4save['full_name'] ) < 3 )      { $error = 'Повна назва занадто коротка!'; $error_area = 'full_name'; }


        if( !$error && !isset($data4save['name']) && isset($original_data['name']) )                { $error = 'Назва не визначена!'; $error_area = 'name'; }
        if( !$error && !isset($data4save['full_name']) && isset($original_data['full_name']) )      { $error = 'Повна назва не визначена!'; $error_area = 'full_name'; }
        if( !$error && !isset($data4save['units_id']) && isset($original_data['units_id']) )        { $error = 'Одиниця виміру не визначена!'; $error_area = 'units'; }

        ///////////
        $SQL = 'SELECT count(id) as count FROM '.$this->table.' WHERE lower("name") = lower(\''.$this->db->safesql($data4save['name']).'\'::text) '. ( isset($original_data['id']) ? ' AND id != '.common::integer($original_data['id']) : ''  ) .';';
        if( $this->db->super_query( $SQL )['count'] > 0 )
        {
            $error = 'Такий запис вже існує!'; $error_area = 'name';
        }
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
        access::check( 'spr', 'edit' );

        if( !$this->table ){ common::err( 'Не зазначена таблиця довідника!' ); };

        $ID = common::integer( $ID );

        if( !is_array($data) ){ return false; }

        $SQL = array();

        foreach( $data as $arg => $value )
        {
            if( in_array( $arg, self::$_columns_not_allowed_to_save ) ){ continue; }
            if( !array_key_exists( $arg, $this->table_info ) ){ continue; }

            $SQL[$arg] = $this->db->safesql( common::filter($value) );
        }

        if( array_key_exists( 'created_by_expert_id', $this->table_info ) ){ $SQL['created_by_expert_id'] = CURRENT_USER_ID; }

        ///////////////////////////////////////////////////

        if( !$this->check_data_before_save( $SQL, $ID?$this->get_raw(array('id'=>$ID))[$ID] : array() ) ){ return false; }

        ///////////////////////////////////////////////////

        if( $ID > 0 )
        {
            foreach( $SQL as $k => $v )
            {
                $SQL[$k] =  '"'.$k.'"= \''.$v.'\'::'.$this->table_info[$k]['data_type'];
            }
            $SQL = 'UPDATE '.$this->table.' SET '.implode( ', ', $SQL ).' WHERE id = '.$ID.' RETURNING id;';
        }
        else
        {
            foreach( $SQL as $k => $v )
            {
                $SQL[$k] =  '\''.$v.'\'::'.$this->table_info[$k]['data_type'];
            }
            $SQL = 'INSERT INTO '.$this->table.' ("'.implode('", "', array_keys($SQL) ).'") VALUES ( '.implode(', ', array_values($SQL)).' ) RETURNING id;';
        }


        //$this->db->query( 'BEGIN;' );
        $SQL = $this->db->query( $SQL );
        $ID = $this->db->get_row( $SQL );
        $ID = isset($ID['id']) ? $ID['id'] : false;

        //if( $ID ){ $this->db->query( 'COMMIT;' ); }
        //     else{ $this->db->query( 'ROLLBACK;' ); }

        $this->db->free();

        cache::clean( self::CACHE_CONST.'-'.$this->table );
        cache::clean( self::CACHE_CONST );
        cache::clean();

        return $ID;
    }

    public final function get_raw( $filters = array() )
    {
        if( !$this->table ){ common::err( 'Не зазначена таблиця довідника!' ); };

        if( is_array($filters) )
        {
            if( isset($filters['id']) ){ $filters['id']     = common::integer( $filters['id'] ); }
        }

        $WHERE = array();

        if( isset($filters['id']) )
        {
            if( is_array($filters['id']) )
            {
                if( count($filters['id']) )
                {
                    $WHERE['id'] = '"'.$this->table.'"."id" IN( '.implode(',', common::integer( $filters['id'] )).' )';
                }
            }
            else
            {
                $WHERE['id'] = '"'.$this->table.'"."id" = \''.common::integer( $filters['id'] ).'\'::INTEGER';
            }

        }
        if( !isset($filters['id']) )    { $WHERE['id'] = '"'.$this->table.'"."id" > 0'; }

        $WHERE = implode( ' AND ', $WHERE );
        $WHERE = common::trim( $WHERE );
        $WHERE = strlen($WHERE)>3 ? 'WHERE '.$WHERE : '';

        $ORDER = array();

        if( array_key_exists( 'position', $this->table_info ) ){ $ORDER[] = '"'.$this->table.'"."position" DESC'; }
        if( array_key_exists( 'name', $this->table_info ) ){ $ORDER[] = '"'.$this->table.'"."name" ASC'; }

        $ORDER = implode( ', ', $ORDER );
        $ORDER = common::trim( $ORDER );
        $ORDER = strlen($ORDER)>3 ? 'ORDER BY '.$ORDER : '';

        $SQL = '
                    SELECT
                        "'.$this->table.'".*
                        '.(($this->table=='reagent')?', "units"."name" as units_name':'').'
                    FROM
                        "'.$this->table.'"
                        '.(($this->table=='reagent')?'LEFT JOIN units ON( units.id = reagent.units_id )':'').'
                    '.$WHERE.'
                    '.$ORDER.'; '.db::CACHED;

        $cache_var = self::CACHE_CONST.'-'.$this->table.'-'.crc32($SQL);

        $data = false;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }

        $SQL = $this->db->query( $SQL );

        $data = array();
        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $data[$row['id']] = $row;
        }

        //var_export($data);echo "\n";

        $this->db->free();

        cache::set( $cache_var, $data );
        return $data;
    }

    private final function check_usage( $element_id = 0 )
    {
        $element_id = common::integer( $element_id );

        if( !$element_id ){ return false; }

        if( !is_array($this->table_info) || !count($this->table_info) || !isset($this->table_info['foreign']) || !is_array($this->table_info['foreign']) || !count($this->table_info['foreign']) )
        {
            return false;
        }

        foreach( $this->table_info['foreign'] as $fk )
        {
            $query = 'SELECT count(*) as count FROM '.$fk['table_name'].' WHERE "'.$fk['column_name'].'" = '.$element_id.';';

            $count = $this->db->super_query( $query );
            $count = common::integer( $count['count'] );

            //echo $query.' -- '.$count."\n";

            if( $count > 0 ){ return $count; }
        }

        return false;
    }

    private final function get_table_info()
    {
        $SQL = 'SELECT
                    column_name,
                    data_type,
                    udt_name,
                    character_maximum_length
                FROM
                    INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = \''.$this->db->safesql($this->table).'\';'.db::CACHED;

        $cache_var = 'spr-tableinfo-'.$this->table;
        $data = cache::get( $cache_var );
        if( $data && is_array($data) && count($data) ){ return $data; }

        $SQL = $this->db->query( $SQL );

        $data = array();
        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $row['character_maximum_length'] = common::integer( $row['character_maximum_length'] );
            $data[$row['column_name']] = $row;
        }

        $SQL = '
            SELECT
                    tc.table_name,
                    kcu.column_name,
                    ccu.table_schema AS foreign_table_schema,
                    ccu.table_name AS foreign_table_name,
                    ccu.column_name AS foreign_column_name
            FROM
                    information_schema.table_constraints AS tc
                    JOIN information_schema.key_column_usage AS kcu
                        ON tc.constraint_name = kcu.constraint_name
                        AND tc.table_schema = kcu.table_schema
                    JOIN information_schema.constraint_column_usage AS ccu
                        ON ccu.constraint_name = tc.constraint_name
                        AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = \'FOREIGN KEY\' AND ccu.table_name=\''.$this->db->safesql($this->table).'\';
        ';
        $SQL = $this->db->query( $SQL );
        $data['foreign'] = array();
        while( ( $row = $this->db->get_row($SQL) ) != false )
        {
            $data['foreign'][] = $row;
        }

        // var_export($data);exit;

        $this->db->free();

        cache::set( $cache_var, $data );
        return $data;
    }


}

