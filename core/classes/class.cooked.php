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



/*
    public final function remove( $reactiv_hash = 0 )
    {
        $reactiv_hash = common::filter_hash( $reactiv_hash );
        $error = '';

        if( !$error && !$reactiv_hash ){ $error = '������������� �� ���������!'; }

        ////////////////////////////////////

        $data = array();
        if( !$error && $reactiv_hash ){ $data = $reactiv_hash?$this->get_raw(array('hash'=>$reactiv_hash))[$reactiv_hash] : array(); }

        if( !$error && ( !is_array($data) || !count($data) ) )                                  { $error = '������� ��������� �����!'; }
        if( !$error && $data['quantity_left'] != $data['quantity_inc'] )                        { $error = '��������� �������� �������, ���� ��� ������ ���������������!';  }

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
    */



    public final function save( $reactiv_hash = false, $data = array() )
    {
        ////////////////////////////////////////////////////////
        // �������� ����������:
        //  0. �������� ����������
        //  1. ��������� ����� � ������� "reactiv", �������� [reactiv.hash]
        //  2. �� ����������� ��������� ����� � ������� "consume", �������� [consume.hash]
        //      2.0. ��������� ������ � ������� "reactiv_ingr_reagent" ��: reactiv_ingr_reagent.reactiv_hash = reactiv.hash
        //      2.1. ��������� �������� ������ � ������� "reactiv_ingr_reagent"    -> ( reactiv.hash, consume.hash )
        //  3. �� ����������� ��������� ����� � ������� "reactiv_consume", �������� [reactiv_consume.hash]
        //      3.0. ��������� ������ � ������� "reactiv_ingr_reactiv" ��: reactiv_ingr_reactiv.reactiv_hash = reactiv.hash
        //      3.1. ��������� �������� ������ � ������� "reactiv_ingr_reactiv"    -> ( reactiv.hash, reactiv_consume.hash )
        //  4. ��������� ����� � ������� "using", �������� [using.hash]
        //      4.0  ��������� ������ � ������� "reactiv_consume_using" ��: reactiv_consume_using.using_hash = using.hash
        //      4.1. ��������� �������� ������ � ������� "reactiv_consume_using"   -> ( using.hash, reactiv_consume.hash )
        //      4.2  ��������� ������ � ������� "consume_using" ��: consume_using.using_hash = using.hash
        //      4.3. ��������� �������� ������ � ������� "consume_using"           -> ( using.hash, consume.hash )
        //  5. �������� ����������
        ////////////////////////////////////////////////////////

        $error = false;
        $reactiv_hash = common::filter_hash( $reactiv_hash );

        if( !is_array($data) )            { return self::error( '������� �������� �����!' ); }
        if( !isset($data['composition']) || !is_array($data['composition']) || !count(($data['composition'])) ){ return self::error( '³������ ���������� ��� ����������!' ); }

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
        if( !isset($purpose['id']) || !$purpose['id'] ) { return self::error( '�������� �������! �� ������� ��������� ���� ������������!', false ); }

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
        $SQL['reactiv']['safe_place']      = common::filter( isset($data['safe_place']) ? $data['safe_place'] : false );
        $SQL['reactiv']['safe_needs']      = common::filter( isset($data['safe_needs']) ? $data['safe_needs'] : false );
        $SQL['reactiv']['comment']         = common::filter( isset($data['comment']) ? $data['comment'] : false );


        if( !$SQL['reactiv']['reactiv_menu_id'] )                                   { return self::error( '������ ������������ �� ���������!',              'reactiv_menu_id' ); }
        if( !$SQL['reactiv']['quantity_inc'] )                                      { return self::error( '�� ��������� ������� ������������� ��������!', 'quantity_inc' ); }
        if( strtotime($SQL['reactiv']['inc_date']) > time() )                       { return self::error( '���� ������������ �� ���� ���� � �����������!',   'inc_date' ); }
        if( strtotime($SQL['reactiv']['inc_date']) < ( time() - $date_diap ) )      { return self::error( '���� ������������ ������� �����!',   'inc_date' ); }

        if( strtotime($SQL['reactiv']['dead_date']) < strtotime($SQL['reactiv']['inc_date']) )  { return self::error( '���� ��������� �� ���� ���� ������ ��� ���� ������������!',   'inc_date|dead_date' ); }
        if( strtotime($SQL['reactiv']['dead_date']) > ( time() + $date_diap ) )                 { return self::error( '���� ��������� ������� �����������! �� ����� ������ �� ��������!',   'dead_date' ); }

        if( strlen($SQL['reactiv']['safe_place']) > 250 )   { return self::error( '̳��� ��������� ������� �����!',   'safe_place' ); }
        if( strlen($SQL['reactiv']['safe_place']) < 3 )     { return self::error( '̳��� ��������� ������� �������!', 'safe_place' ); }

        if( strlen($SQL['reactiv']['safe_needs']) > 250 )   { return self::error( '����� ��������� ������� ����!',   'safe_needs' ); }
        if( strlen($SQL['reactiv']['safe_needs']) < 3 )     { return self::error( '����� ��������� ������� ������!', 'safe_needs' ); }

        if( strlen($SQL['reactiv']['comment']) > 1000 )     { return self::error( '�������� ������� ������! �� ���� �� ��� �������!', 'comment' ); }

        //////////////////////////////////////////////////
        $SQL['consume'] = array();
        $SQL['consume']['reagent'] = array();
        $SQL['consume']['reactiv'] = array();

        if( !is_array($data['composition']) || !count($data['composition']) )
        {
            return self::error( '�� ���������� ����� ��������! ������� ����䳺���!' );
        }
        else
        {
            foreach( $data['composition'] as $ingridient )
            {
                $ingridient = common::filter( $ingridient );

                if( $ingridient['role'] == 'reagent' )
                {                              // consume_hash
                    $SQL['consume']['reagent'][$ingridient['dispersion_id']] = array
                    (
                        'dispersion_id' => common::integer( $ingridient['dispersion_id'] ),
                        'quantity'      => common::float( $ingridient['quantity'] ),
                        'inc_expert_id' => common::integer( $SQL['reactiv']['inc_expert_id'] ),
                        'date'          => $SQL['reactiv']['inc_date'],
                    );

                    if( !isset($ingridient['consume_hash']) || !$ingridient['consume_hash'] )
                    {
                        $SQL['consume']['reagent'][$ingridient['dispersion_id']]['query'] =
                            'INSERT INTO consume '.db::array2ins( $SQL['consume']['reagent'][$ingridient['dispersion_id']] ).' RETURNING hash;';
                    }
                    else
                    {
                        $SQL['consume']['reagent'][$ingridient['dispersion_id']]['query'] =
                            'UPDATE consume SET '.db::array2upd( $SQL['consume']['reagent'][$ingridient['dispersion_id']] ).' WHERE hash = \''.$this->db->safesql($ingridient['consume_hash']).'\' RETURNING hash;';
                    }
                }

            }
        }
        //////////////////////////////////////////////////

        // STEP 0: BEGIN TRANSACTION
        $this->db->query( 'BEGIN;' );
        ///////////////////////////////

        // STEP 1: INS data to "reactiv"
        $SQL['reactiv']['query'] = !$reactiv_hash
            ?   'INSERT INTO reactiv '.db::array2ins( $SQL['reactiv'] )
            :   'UPDATE reactiv SET '.db::array2upd( $SQL['reactiv'] ).' WHERE hash = \''.$this->db->safesql($reactiv_hash).'\' ';
        $SQL['reactiv']['query'] = $SQL['reactiv']['query'].' RETURNING hash;';

        $SQL['reactiv']['hash'] = $reactiv_hash = $this->db->super_query( $SQL['reactiv']['query'] )['hash'];

        if( !$reactiv_hash )
        {
            $this->db->query( 'ROLLBACK;' );
            return self::error( 'reactiv hash error!' );
        }
        ///////////////////////////////

        // STEP 2: INS data to "consume"
        $consume_hash = array();
        $this->db->query( 'DELETE FROM reactiv_ingr_reagent WHERE reactiv_hash = \''.$reactiv_hash.'\';' );
        foreach( $SQL['consume']['reagent'] as $ingridient_id => $ingridient )
        {
            $SQL['consume']['reagent'][$ingridient_id]['query'];
            $consume_hash[] = $SQL['consume']['reagent'][$ingridient_id]['hash'] = $this->db->super_query( $SQL['consume']['reagent'][$ingridient_id]['query'] )['hash'];

            if( !$SQL['consume']['reagent'][$ingridient_id]['hash'] )
            {
                $this->db->query( 'ROLLBACK;' );
                return self::error( 'consume hash error!' );
            }

            $SQL['consume']['reagent'][$ingridient_id]['merge_query'] = 'INSERT INTO reactiv_ingr_reagent ( reactiv_hash, consume_hash ) VALUES ( \''.$reactiv_hash.'\', \''.$SQL['consume']['reagent'][$ingridient_id]['hash'].'\' ); ';
            $this->db->query( $SQL['consume']['reagent'][$ingridient_id]['merge_query'] );
        }
        ///////////////////////////////

        // STEP 4: INS data to "using"
        $SQL['using'] = array();

        $SQL['using']['select'] = 'SELECT DISTINCT ON( "using".hash ) "using".* FROM "using" LEFT JOIN consume_using ON( consume_using.using_hash = "using".hash ) LEFT JOIN reactiv_consume_using ON( reactiv_consume_using.using_hash = "using".hash ) WHERE reactiv_consume_using.consume_hash IN( \'asd\' ) OR consume_using.consume_hash IN( \''.implode('\', \'', $consume_hash).'\' );';
        $SQL['using'] = array_merge( $SQL['using'], $this->db->super_query( $SQL['using']['select'] ) );

        $SQL['using']['data'] = array
        (
            'purpose_id' => $purpose['id'],
            'group_id' => CURRENT_GROUP_ID,
            'date' => $SQL['reactiv']['inc_date'],
        );

        if( !isset($SQL['using']['hash']) )
        {
            $SQL['using']['data'] = 'INSERT INTO "using" '.db::array2ins( $SQL['using']['data'] ).' RETURNING hash;';
        }
        else
        {
            $SQL['using']['data'] = 'UPDATE "using" SET '.db::array2upd( $SQL['using']['data'] ).' WHERE hash=\''.$SQL['using']['hash'].'\' RETURNING hash;';
        }

        $SQL['using'] = array_merge( $SQL['using'], $this->db->super_query( $SQL['using']['data'] ) );

        $this->db->query( 'DELETE FROM consume_using WHERE consume_hash IN(\''.implode( '\', \'', $consume_hash ).'\');' );
        $SQL['using']['merge_query'] = array();
        foreach( $consume_hash as $single_consume_hash )
        {
            $SQL['using']['merge_query'][] = '(\''.$SQL['using']['hash'].'\',\''.$single_consume_hash.'\')';
        }
        $SQL['using']['merge_query'] = 'INSERT INTO consume_using (using_hash,consume_hash) VALUES '.implode( ', ', $SQL['using']['merge_query'] ).';';
        $this->db->query( $SQL['using']['merge_query'] );
        ///////////////////////////////




        //var_export($SQL);exit;


        $this->db->query( 'COMMIT;' );
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
        foreach( $data as $area => $area_data )
        {
            foreach( $area_data as $line )
            {
                $tpl->load( $skin );

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

                $tpl->compile( $skin );
            }
        }

        return $tpl->result( $skin );
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
        $tpl->set( '{ingridients}',
                        $this->get_html( array(), 'cooked/ingridient_reactive' )."\n\n".
                        ( new dispersion )->get_html( array(), 'cooked/ingridient_reagent' )
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

            if( isset( $units[$line['units_id']] ) )
            {
                foreach( $units[$line['units_id']] as $key => $value )
                {
                    if( is_array($value) ){ continue; }

                    $tags[] = '{tag:units:'.$key.'}';
                    $tpl->set( '{tag:units:'.$key.'}', common::db2html( $value ) );
                }
            }
            /*
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
            */
            $tpl->compile( $skin );
        }



        return $tpl->result( $skin );
    }


    public final function get_raw( $filters = array() )
    {
        $WHERE = array();

        $WHERE['reactiv.hash'] = 'reactiv.hash != \'\'';
        $WHERE['reactiv.group_id'] = '( reactiv.group_id = \''.CURRENT_GROUP_ID.'\'::INTEGER OR reactiv.group_id = 0 )';

        if( is_array($filters) )
        {
            if( isset($filters['hash']) )
            {
                $filters['hash'] = common::filter_hash( $filters['hash'] );
                $filters['hash'] = is_array($filters['hash']) ? $filters['hash'] : array( $filters['hash'] );

                if( count($filters['hash']) )
                {
                    $WHERE['reactiv.hash']   = 'reactiv.hash IN (\''.implode( '\', \'', $filters['hash'] ).'\')';
                }
            }

            /*if( isset($filters['using_hash']) )
            {
                $filters['using_hash'] = common::filter_hash( $filters['using_hash'] );
                $filters['using_hash'] = is_array($filters['using_hash']) ? $filters['using_hash'] : array( $filters['using_hash'] );

                if( count($filters['using_hash']) )
                {
                    $WHERE['using.hash']   = '"using".hash IN (\''.implode( '\', \'', $filters['using_hash'] ).'\')';
                }
            }*/

            /*if( isset($filters['quantity_left:more']) )
            {
                $filters['quantity_left:more'] = common::float( $filters['quantity_left:more'] );
                $WHERE['quantity_left:more'] = ' reactiv.quantity_left > \''.$filters['quantity_left:more'].'\'::FLOAT';
            }

            if( isset($filters['quantity_left:less']) )
            {
                $filters['quantity_left:less'] = common::float( $filters['quantity_left:less'] );
                $WHERE['quantity_left:less'] = ' reactiv.quantity_left < \''.$filters['quantity_left:less'].'\'::FLOAT';
            }

            if( isset($filters['quantity_left:is']) )
            {
                $filters['quantity_left:is'] = common::float( $filters['quantity_left:is'] );
                $WHERE['quantity_left:is'] = ' reactiv.quantity_left = \''.$filters['quantity_left:is'].'\'::FLOAT';
            }*/

        }

        $WHERE = count($WHERE) ? 'WHERE '.implode( ' AND ', $WHERE ) : '';

        $SQL = '
            SELECT
                reactiv.*,
                reactiv_menu.name as reactiv_menu_name,
                reactiv_menu.units_id,
                units.name as units_name,
                units.short_name as units_short_name
            FROM
                reactiv
                LEFT JOIN reactiv_menu ON( reactiv_menu.id = reactiv.reactiv_menu_id )
                LEFT JOIN units ON( units.id = reactiv_menu.units_id )
            '.$WHERE.'
            ORDER by
                reactiv.inc_date DESC;
                '.db::CACHED;

        //echo $SQL;

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
            // ������� ���вĲ���� (��������) //
            $SQL = '
                SELECT
                    reactiv_ingr_reagent.reactiv_hash 	as hash,
                    consume.hash 						as consume_hash,
                    "using".hash 						as using_hash,
                    consume.quantity	                as consume_quantity,
                    dispersion.id					    as dispersion_id,
                    stock.id						    as stock_id,
                    stock.reagent_id				    as reagent_id
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

                if( !$data[$row['hash']]['using_hash'] ){ $data[$row['hash']]['using_hash'] = $row['using_hash']; }
                if( $data[$row['hash']]['using_hash'] != $row['using_hash'] )
                {
                    return self::error( 'Problems with "using_hash"! Hash is different at one reactive!' );
                }
            }


            // ������� ���вĲ���� (�������) //
            $SQL = '
                SELECT
                    reactiv_ingr_reactiv.hash 	    as hash,
                    reactiv_consume.hash 	        as consume_hash,
                    reactiv_consume.quantity 		as consume_quantity,
                    reactiv.hash			        as reactiv_hash,
                    "using".hash			        as using_hash
                FROM
                    reactiv_ingr_reactiv
                    LEFT JOIN reactiv_consume ON( reactiv_consume.hash = reactiv_ingr_reactiv.consume_hash )
                    LEFT JOIN reactiv 		  ON( reactiv.hash = reactiv_consume.reactive_hash )

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

                if( !$data[$row['hash']]['using_hash'] ){ $data[$row['hash']]['using_hash'] = $row['using_hash']; }
                if( $data[$row['hash']]['using_hash'] != $row['using_hash'] )
                {
                    return self::error( 'Problems with "using_hash"! Hash is different at one reactive!' );
                }
            }

            // ������� ���-���� ������������ //

        }
        //////////////////////////////////////////////////////////////////////////////////

        cache::set( $cache_var, $data );
        return $data;
    }

}