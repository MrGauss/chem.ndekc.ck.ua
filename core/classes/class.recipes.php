<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }
if( !class_exists( 'spr_manager' ) ){ require( CLASSES_DIR.DS.'class.spr_manager.php' ); }


class recipes
{
    use basic, spr, db_connect;

    const DB_MAIN_TABLE = 'reactiv_menu';
    const CACHE_CONST   = 'spr';

    public final function remove( $ID = 0 )
    {
        $ID = common::integer( $ID );
        $error = '';

        if( !$error && !$ID ){ $error = 'Ідентифікатор не визначено!'; }

        ////////////////////////////////////
        if( !$error && $ID )
        {
            $count = $this->db->super_query( 'SELECT count(hash) as count FROM reactiv WHERE reactiv_menu_id = '.$ID.';' )['count'];
            if( $count > 0 ){ $error = 'Запис використовується! В видаленні відмовлено!'; }
        }

        ////////////////////////////////////

        if( $error != false )
        {
            if( _AJAX_ ){ ajax::set_error( rand(10,99), $error ); return false; }
            else        { common::err( $error ); return false; }
        }

        if( !$error )
        {
            $this->db->query( 'BEGIN;' );
            $this->db->query( 'DELETE FROM '.self::DB_MAIN_TABLE.' WHERE id='.$ID.';' );
            $this->db->query( 'DELETE FROM reactiv_menu_ingredients WHERE reactiv_menu_id='.$ID.';' );
            $this->db->query( 'COMMIT;' );
        }

        cache::clean( self::CACHE_CONST );
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

        ///////////
        $SQL = 'SELECT count(id) as count FROM reactiv_menu WHERE lower("name") = lower(\''.$this->db->safesql($data4save['name']).'\'::text) '. ( isset($original_data['id']) ? ' AND id != '.common::integer($original_data['id']) : ''  ) .';';
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
        $ID = common::integer( $ID );

        if( !is_array($data) ){ return false; }


        $data['name'] = common::filter( isset($data['name'])?$data['name']:'' );

        $data['ingredients'] = common::filter( isset($data['ingredients'])?$data['ingredients']:'' );
        $data['ingredients'] = is_array( $data['ingredients'] ) ? $data['ingredients'] : array( $data['ingredients'] );
        $data['ingredients'] = common::trim( $data['ingredients'] );
        $data['ingredients'] = common::integer( $data['ingredients'] );
        $data['ingredients'] = array_unique( $data['ingredients'] );

        ///////////////////////////////////////////////////

        $SQL = array();
        $SQL['name'] = $this->db->safesql( $data['name'] );

        ///////////////////////////////////////////////////

        if( !$this->check_data_before_save( $SQL, $ID?$this->get_raw(array('id'=>$ID))[$ID] : array() ) ){ return false; }

        ///////////////////////////////////////////////////

        if( $ID > 0 )
        {
            foreach( $SQL as $k => $v )
            {
                $SQL[$k] =  '"'.$k.'"= \''.$v.'\'';
            }
            $SQL = 'UPDATE reactiv_menu SET '.implode( ', ', $SQL ).' WHERE id = '.$ID.' RETURNING id;';
        }
        else
        {
            $SQL = 'INSERT INTO reactiv_menu ("'.implode('", "', array_keys($SQL) ).'") VALUES ( \''.implode('\', \'', array_values($SQL)).'\' ) RETURNING id;';
        }

        $this->db->query( 'BEGIN;' );
        $SQL = $this->db->query( $SQL );
        $ID = $this->db->get_row( $SQL );
        $ID = isset($ID['id']) ? $ID['id'] : false;

        if( $ID > 0 )
        {
            $ingrSQL = array();
            foreach( $data['ingredients'] as $ingr_id )
            {
                if( $ingr_id < 1 ){ continue; }

                $ingrSQL[] = '( '.$ID.', '.$ingr_id.' )';
            }

            if( is_array($ingrSQL) )
            {
                $ingrSQL = 'INSERT INTO reactiv_menu_ingredients ( reactiv_menu_id, reagent_id ) VALUES '.implode( ', ', $ingrSQL ).';';

                $this->db->query( 'DELETE FROM reactiv_menu_ingredients WHERE reactiv_menu_id = '.$ID.';' );
                $this->db->query( $ingrSQL );
            }
        }

        if( $ID ){ $this->db->query( 'COMMIT;' ); }
             else{ $this->db->query( 'ROLLBACK;' ); }

        $this->db->free();

        cache::clean( self::CACHE_CONST );
        cache::clean();

        return $ID;
    }

    public final function get_html( $filters = array(), $skin = false )
    {
        $data = $this->get_raw( $filters );
        $data = is_array($data) ? $data : array();

        $reagent = new spr_manager( 'reagent' );
        $reagent = $reagent->get_raw();

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

            $line['ingredients_html'] = array();
            foreach( $line['ingredients'] as $ingredient_id => $ingredient_data )
            {
                $line['ingredients_html'][] = '<span data-reagent_id="'.$ingredient_data['reagent_id'].'" title="'.common::db2html( $reagent[$ingredient_data['reagent_id']]['name'] ).'">'.common::db2html( $reagent[$ingredient_data['reagent_id']]['name'] ).'</span>';
            }
            $line['ingredients_html'] = implode( ' ', $line['ingredients_html'] );
            $tpl->set( '{tag:ingredients_html}', $line['ingredients_html'] );

            unset( $line['ingredients_html'] );

            $tpl->compile( $skin );
        }

        return $tpl->result( $skin );
    }

    public final function editor( $line_id = 0, $skin = false )
    {
        $line_id = common::integer( $line_id );

        $reagent = new spr_manager( 'reagent' );
        $reagent = $reagent->get_raw();

        $data = $this->get_raw( array( 'id' => $line_id ) );
        $data = isset( $data[$line_id] ) ? $data[$line_id] : false;

        if( !is_array($data) ){ return false; }

        $tpl = new tpl;

        $tpl->load( $skin );

        $data['key'] = common::key_gen( $line_id );

        foreach( $data as $k => $v )
        {
            if( is_array($v) ){ continue; }

            $tpl->set( '{tag:'.$k.'}', common::db2html( $v ) );
        }

        $data['ingredients_html'] = array();
        foreach( $data['ingredients'] as $ingredient_id => $ingredient_data )
        {
            $data['ingredients_html'][] = '<div class="ingredient" data-reagent_id="'.$ingredient_data['reagent_id'].'" title="'.common::db2html( $reagent[$ingredient_data['reagent_id']]['name'] ).'">'.common::db2html( $reagent[$ingredient_data['reagent_id']]['name'] ).'</div>';
        }
        $data['ingredients_html'] = implode( ' ', $data['ingredients_html'] );
        $tpl->set( '{tag:ingredients_html}', $data['ingredients_html'] );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function get_raw( $filters = array() )
    {
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
                    $WHERE['id'] = 'id IN( '.implode(',', common::integer( $filters['id'] )).' )';
                }
            }
            else
            {
                $WHERE['id'] = 'id = \''.common::integer( $filters['id'] ).'\'::INTEGER';
            }

        }
        if( !isset($filters['id']) )    { $WHERE['id'] = 'id > 0'; }

        $WHERE = implode( ' AND ', $WHERE );
        $WHERE = common::trim( $WHERE );
        $WHERE = strlen($WHERE)>3 ? 'WHERE '.$WHERE : '';


        $SQL = '
                    SELECT
                        *
                    FROM
                       '.self::DB_MAIN_TABLE.'
                    '.$WHERE.'
                    ORDER by name; '.db::CACHED;

        $cache_var = 'spr-'.self::DB_MAIN_TABLE.'-'.md5( $SQL ).'';
        $data = cache::get( $cache_var );

        $data = false;

        if( $data && is_array($data) && count($data) ){ return $data; }
        $data = array();

        $SQL = $this->db->query( $SQL );

        while( ( $row = $this->db->get_row($SQL) ) !== false )
        {
            $data[$row['id']] = $row;
            $data[$row['id']]['ingredients'] = array();
        }

        if( count($data) )
        {
            $SQL = '
                SELECT
                    *
                FROM
                    reactiv_menu_ingredients
                WHERE
                    reactiv_menu_id IN( '. implode( ',', array_keys( $data ) ) .' )
                ORDER BY
                    reagent_id ASC;
                '.db::CACHED;

            $SQL = $this->db->query( $SQL );

            while( ( $row = $this->db->get_row($SQL) ) !== false )
            {
                if( !isset($data[$row['reactiv_menu_id']]['ingredients']) ){ $data[$row['reactiv_menu_id']]['ingredients'] = array(); }
                $data[$row['reactiv_menu_id']]['ingredients'][$row['reagent_id']] = $row;
            }
        }

        cache::set( $cache_var, $data );
        return $data;
    }


}
