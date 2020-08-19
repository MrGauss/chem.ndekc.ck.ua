<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )        { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )          { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) )   { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class transfer
{
    use basic, spr, db_connect;

    public final function get_user_select( $group_id = 0 )
    {
        $users = ( new user )->get_raw( array( 'group_id' => common::integer( $group_id ) ) );

        foreach( $users as $user_id => $user )
        {
            if( $user['visible'] != 1 ){ unset( $users[$user_id] ); continue; }
            $users[$user_id] = '<option value="'.$user_id.'">'. common::db2html( $user['surname'].' '.$user['name'].' '.$user['phname'] ) .'</option>';
        }
        return implode( "\n", $users );
    }

    public final function get_reagent_select( $group_id = 0 )
    {
        $reagents = (new spr_manager( 'reagent' ) )->get_raw( array( 'group_id' => common::integer( $group_id ) ) );

        foreach( $reagents as $reagent_id => $reagent )
        {
            $reagents[$reagent_id] = '<option value="'.$reagent_id.'">'. common::db2html( $reagent['name'] ) .'</option>';
        }
        return implode( "\n", $reagents );
    }

    public final function editor( $id = 0 )
    {
        access::check( 'stock', 'view' );

        $skin = 'transfer/editor';

        $line_id = mt_rand( 1000, 7382749 );

        $tpl = new tpl;

        $tpl->load( $skin );

        $tpl->set( '{tag:id}', $line_id );
        $tpl->set( '{tag:key}', common::key_gen( $line_id ) );

        $tpl->compile( $skin );

        return $tpl->result( $skin );
    }

    public final function save( $data = array() )
    {
        $data = array
        (
            'stock_id'          => common::integer( isset($data['stock_id'])?$data['stock_id']:0 ),
            'reagent_id'        => common::integer( isset($data['reagent_id'])?$data['reagent_id']:0 ),
            'quantity'          => common::float( isset($data['quantity'])?$data['quantity']:0 ),
            'from_expert_id'    => common::integer( isset($data['from_expert_id'])?$data['from_expert_id']:0 ),
            'to_expert_id'      => common::integer( isset($data['to_expert_id'])?$data['to_expert_id']:0 ),
            'to_reagent_id'     => common::integer( isset($data['to_reagent_id'])?$data['to_reagent_id']:0 ),
        );

        $data['from_expert_id'] = CURRENT_USER_ID;

        if( !$data['stock_id'] )        { return self::error( 'Невідомо що передавати!', 'reagent_id' ); }
        if( !$data['reagent_id'] )      { return self::error( 'Невідомо що передавати!', 'reagent_id' ); }
        if( !$data['quantity'] )        { return self::error( 'Зазначте кількість!', 'quantity' );       }
        if( !$data['from_expert_id'] )  { return self::error( 'Хто передає?', 'from_expert_id' );        }
        if( !$data['to_expert_id'] )    { return self::error( 'Зазначте хто отримує!', 'to_expert_id' ); }
        if( !$data['to_reagent_id'] )   { return self::error( 'Зазначте яку назву має реагент в іншій лабораторії!', 'to_reagent_id' ); }

        //var_export($data);exit;

        $from_user = ( new user )->get_raw( array( 'id' => $data['from_expert_id'] ) );
        $to_user   = ( new user )->get_raw( array( 'id' => $data['to_expert_id'] ) );

        if( !is_array($from_user) || !isset($from_user[$data['from_expert_id']]) || !is_array($from_user[$data['from_expert_id']]) )
        {
            return self::error( 'Користувач не знайдений! (може в бан?)', 'from_expert_id' );
        }else{ $from_user = $from_user[$data['from_expert_id']]; }

        if( !is_array($to_user) || !isset($to_user[$data['to_expert_id']]) || !is_array($to_user[$data['to_expert_id']]) )
        {
            return self::error( 'Користувач не знайдений! (може в бан?)', 'to_expert_id' );
        }else{ $to_user = $to_user[$data['to_expert_id']]; }

        if( $from_user['region_id'] != $to_user['region_id'] ){ return self::error( 'Вам заборонено передавати реактиви чи матеріали між регіонами!', 'from_expert_id|to_expert_id' ); }
        if( $from_user['group_id'] == $to_user['group_id'] ){ return self::error( 'Неможливо здійснити трансфер в межах одного складу!', 'from_expert_id|to_expert_id' ); }

        if( !access::allow( 'stock', 'edit', $data['to_expert_id'] ) ){ return self::error( 'Обраний Вами експерт не може вносити приймати матеріали чи реактиви!', 'to_expert_id' ); }

        $stock = ( new stock ) ->get_raw( array( 'id' => $data['stock_id'] ) );

        if( !is_array($stock) || !isset($stock[$data['stock_id']]) || !is_array($stock[$data['stock_id']]) )
        {
            return self::error( 'Неможливо знайти що передаємо! Хуйня якась...', 'reagent_id' );
        }else{ $stock = $stock[$data['stock_id']]; }

        if( $stock['group_id'] != $from_user['group_id'] ){ return self::error( 'І куди ми ліземо?', 'reagent_id|from_expert_id' ); }

        if( $data['quantity'] > common::float( $stock['quantity_left'] ) ){ return self::error( 'Ви намагаєтесь передати більше ніж є на складі!', 'quantity' ); }

        $from_group = ( new spr_manager('groups') )->get_raw( array('id'=>$from_user['group_id']) )[$from_user['group_id']];

        ///////////////////////////////////////////
        $this->db->transaction_start();

        $SQL = array();
        $SQL['inc_expert_id']       = $data['to_expert_id'];
        $SQL['group_id']            = $to_user['group_id'];
        $SQL['reagent_id']          = common::integer($data['to_reagent_id']);
        $SQL['reagent_state_id']    = common::integer($stock['reagent_state_id']);
        $SQL['clearence_id']        = common::integer($stock['clearence_id']);
        $SQL['is_sertificat']       = common::integer($stock['is_sertificat']);
        $SQL['is_suitability']      = common::integer($stock['is_suitability']);
        $SQL['danger_class_id']     = common::integer($stock['danger_class_id']);
        $SQL['quantity_inc']        = common::float( $data['quantity'] );
        $SQL['inc_date']            = common::en_date($stock['inc_date']     ,'Y-m-d');
        $SQL['create_date']         = common::en_date($stock['create_date']  ,'Y-m-d');
        $SQL['dead_date']           = common::en_date($stock['dead_date']    ,'Y-m-d');
        $SQL['nakladna_date']       = common::en_date($stock['nakladna_date']    ,'Y-m-d');
        $SQL['nakladna_num']        = common::filter( isset($stock['nakladna_num'])?$stock['nakladna_num']:'' );
        $SQL['creator']             = common::filter( isset($stock['creator'])?$stock['creator']:'' );
        $SQL['provider']            = common::filter( isset($stock['provider'])?$stock['provider']:'' );
        $SQL['safe_needs']          = common::filter('');
        $SQL['safe_place']          = common::filter('');
        $SQL['comment']             = common::filter( 'Передано з "'.common::trim( $from_group['name'] ).'" '.date( 'Y.m.d H:i:s' ).'. Передав '.$from_user['surname'].' '.$from_user['name'].' '.$from_user['phname'].'. Отримав '.$to_user['surname'].' '.$to_user['name'].' '.$to_user['phname'].'.' );

        $SQL = array_map( array( $this->db, 'safesql' ), $SQL );

        $SQL = 'INSERT INTO stock ( "'.implode('", "', array_keys($SQL)).'" ) VALUES (\''.implode( '\', \'', array_values($SQL) ).'\') RETURNING id;';
        $SQL = $this->db->query( $SQL );
        $new_stock_id = $this->db->get_row( $SQL );

        if( !is_array($new_stock_id) || !isset($new_stock_id['id']) || ( $new_stock_id = common::integer( $new_stock_id['id'] ) ) == 0 )
        {
            $this->db->transaction_rollback();
            return self::error( 'Неможливо зберегти дані!' );
        }

        $SQL = 'UPDATE stock SET quantity_inc = quantity_inc - '.$data['quantity'].'  WHERE id='.$data['stock_id'].' AND group_id='.$stock['group_id'].';';
        $this->db->query( $SQL );

        $SQL = array();
        $SQL['from_stock_id']   = common::integer( $data['stock_id'] );
        $SQL['to_stock_id']     = common::integer( $new_stock_id );
        $SQL['from_expert_id']  = common::integer( $data['from_expert_id'] );
        $SQL['to_expert_id']    = common::integer( $data['to_expert_id'] );
        $SQL['date']            = date('Y-m-d H:i:s');
        $SQL['quantity']        = common::float( $data['quantity'] );
        $SQL['info']            = common::filter( 'Передано з "'.common::trim( $from_group['name'] ).'" '.date( 'Y.m.d H:i:s' ).'. Передав '.$from_user['surname'].' '.$from_user['name'].' '.$from_user['phname'].'. Отримав '.$to_user['surname'].' '.$to_user['name'].' '.$to_user['phname'].'.' );

        $SQL = 'INSERT INTO transfer ( "'.implode('", "', array_keys($SQL)).'" ) VALUES (\''.implode( '\', \'', array_values($SQL) ).'\') RETURNING id;';
        $SQL = $this->db->query( $SQL );
        $transfer_id = $this->db->get_row( $SQL );

        if( !is_array($transfer_id) || !isset($transfer_id['id']) || ( $transfer_id = common::integer( $transfer_id['id'] ) ) == 0 )
        {
            $this->db->transaction_rollback();
            return self::error( 'Неможливо зберегти дані!' );
        }

        ///////////////////////////////////////////

        $this->db->transaction_commit();
        $this->db->free();

        cache::clean();

        return $transfer_id;
    }

    public final function remove( $id = 0 )
    {

    }

    public final function get_raw( $filters = array() )
    {
        if( !isset($filters['from_stock_id']) ){ return array(); }

        $SQL = '
                SELECT
                    *
                FROM transfer
                WHERE id > 0 AND from_stock_id = '.common::integer( $filters['from_stock_id'] ).'
                ORDER by date DESC;
                ;';
        $SQL = $this->db->query( $SQL );

        $data = array();
        while( ( $row = $this->db->get_row( $SQL ) ) !== false )
        {
            $data[$row['id']] = $row;
        }

        return $data;
    }

}