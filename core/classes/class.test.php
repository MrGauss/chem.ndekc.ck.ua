<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

if( !trait_exists( 'basic' ) )      { require( CLASSES_DIR.DS.'trait.basic.php' ); }
if( !trait_exists( 'spr' ) )        { require( CLASSES_DIR.DS.'trait.spr.php' ); }
if( !trait_exists( 'db_connect' ) ) { require( CLASSES_DIR.DS.'trait.db_connect.php' ); }

class test
{
    use basic, spr, db_connect;

    public final static function arr_rand( $array )
    {
        shuffle($array);
        return $array[0];
    }

    public final function create_using()
    {
        $using       = new using;
        $dispersion  = ( new dispersion )->get_raw( array( 'is_dead' => 0, 'quantity_left:more' => 0 ) );
        $cooked      = ( new cooked )->get_raw( array( 'is_dead' => 0, 'quantity_left:more' => 0 ) );

        $dispersion_keys = array_keys($dispersion);
        $cooked_keys = array_keys($cooked);

        $purpose = array( 1, 2, 5 );

        $time_day  = 60*60*24;
        $time_year = $time_day * 365;

        $N = 100;
        $I = 2;

        while( $I <= $N )
        {
            $data = array();
            $data['consume'] = array();
            $data['reactiv_consume'] = array();

            shuffle( $dispersion_keys );
            $ingridients_reagent = array_slice( $dispersion_keys, 0, mt_rand( 1, 6 ) );
            $ingridients_reagent = ( mt_rand( 1, 10 ) > 2 ) ? $ingridients_reagent : array();
            $ingridients_reagent = array_unique( $ingridients_reagent );

            shuffle( $cooked_keys );
            $ingridients_reactiv = array_slice( $cooked_keys, 0, mt_rand( 1, 4 ) );
            $ingridients_reactiv = ( mt_rand( 1, 10 ) > 6 ) ? $ingridients_reactiv : array();
            $ingridients_reactiv = array_unique( $ingridients_reactiv );

            if( !count($ingridients_reagent) && !count($ingridients_reactiv) )
            {
                continue;
            }

            $max_date = 0;
            foreach( $ingridients_reagent as $reagent_id )
            {
                if( !$dispersion[$reagent_id]['quantity_left'] ){ return false; }

                $t = strtotime($dispersion[$reagent_id]['inc_date']);

                if( $t > $max_date ){ $max_date = $t; }

                $d = array(1, floor( $dispersion[$reagent_id]['quantity_left']/10 ));
                sort($d);
                $data['consume'][$reagent_id] = array
                (
                    'dispersion_id' => $reagent_id,
                    'quantity' => mt_rand( $d[0], $d[1] ),
                );
                if( $data['consume'][$reagent_id] < 1 ){ $data['consume'][$reagent_id] = 1; }
            }

            $data['date'] = date( 'Y-m-d', mt_rand( $max_date, time() - $time_day ) );
            $data['purpose_id'] = self::arr_rand( $purpose );
            $data['exp_number'] = 'test-'.date( 'Y', strtotime($data['date']) ).'-'.mt_rand( 1, 1000 );
            $data['obj_count']  = mt_rand( 1, 100 );
            $data['expert_id']  = CURRENT_USER_ID;
            $data['tech_info']  = 'Тестове використання '.date( 'Y', strtotime($data['date']) ).'-'.$I;
            $data['ucomment']   = 'Тестове використання '.date( 'Y', strtotime($data['date']) ).'-'.$I;

            $using->save( false, $data );

            $I++;
        }

    }

    public final function create_dispersion()
    {
        $stock = ( new stock )->get_raw();

        $time_day  = 60*60*24;
        $time_year = $time_day * 365;

        $dispersion = new dispersion;

        foreach( $stock as $stock_id => $stock_data )
        {
            if( !$stock_data['quantity_left'] ){ continue; }

            $data['inc_expert_id']       = CURRENT_USER_ID;
            $data['group_id']            = CURRENT_GROUP_ID;
            $data['stock_id']            = $stock_id;
            $data['out_expert_id']       = CURRENT_USER_ID;
            $data['quantity_inc']        = ceil( $stock_data['quantity_inc'] / mt_rand( 2, 5 ) );

            if( $data['quantity_inc'] > $stock_data['quantity_left'] ){ $data['quantity_inc'] = $stock_data['quantity_left']; }

            $data['inc_date']            = date( 'Y-m-d', strtotime($stock_data['inc_date']) + $time_day * mt_rand(1,30) );
            $data['comment']             = 'Запис створено автоматично';

            $dispersion->save( 0, $data );
        }


    }

    public final function create_stock()
    {
        $reagent = ( new spr_manager( 'reagent' ) )->get_raw();
        $reagent_state = ( new spr_manager( 'reagent_state' ) )->get_raw();
        $clearence = ( new spr_manager( 'clearence' ) )->get_raw();
        $danger_class = ( new spr_manager( 'danger_class' ) )->get_raw();

        $_stock = new stock;

        $time_day  = 60*60*24;
        $time_year = $time_day * 365;

        foreach( $reagent as $reagent_id => $reagent_data )
        {
            $date_rand = mt_rand( strtotime( '2015-02-09' ), time() - ($time_day*mt_rand( 1, 90 )) );

            $data['inc_expert_id']       = CURRENT_USER_ID;
            $data['group_id']            = CURRENT_GROUP_ID;
            $data['reagent_id']          = $reagent_id;
            $data['reagent_state_id']    = self::arr_rand( array_keys( $reagent_state ) );
            $data['clearence_id']        = self::arr_rand( array_keys( $clearence ) );
            $data['is_sertificat']       = mt_rand( 0, 1 );
            $data['is_suitability']      = mt_rand( 0, 1 );
            $data['danger_class_id']     = self::arr_rand( array_keys( $danger_class ) );

            $data['quantity_inc']        = common::float( mt_rand( 1, 30 )*100 );

            $data['inc_date']            = date( 'Y-m-d', $date_rand );
            $data['create_date']         = date( 'Y-m-d', $date_rand - $time_day*mt_rand( 10, 100 ) );
            $data['dead_date']           = date( 'Y-m-d', time() + $time_year * mt_rand( 2, 6 ) );

            $data['nakladna_date']       = date( 'Y-m-d', $date_rand );
            $data['nakladna_num']        = substr( str_shuffle(md5( $date_rand )), 0, 16 );

            $data['creator']             = 'Тестовий виробник '.mt_rand( 1, 100 );
            $data['provider']            = 'Тестовий постачальник '.mt_rand( 1, 100 );

            $data['safe_needs']          = 'Тестові умови '.mt_rand( 1, 100 );
            $data['safe_place']          = 'Тестове місце '.mt_rand( 1, 100 );
            $data['comment']             = 'Запис створено автоматично';

            $_stock->save( 0, $data );
        }

    }

    public final function create_recipe()
    {
        $N = 10;
        $I = 1;

        $units          = ( new spr_manager( 'units' ) )    ->get_raw();
        $reagent        = ( new spr_manager( 'reagent' ) )  ->get_raw();

        foreach( $reagent as $k => $v )
        {
            if( !preg_match( '!liquid|powder|solid!is', $v['name'] ) )
            {
                unset( $reagent[$k] );
            }
        }

        $_recipes = new recipes;

        while( $I <= $N )
        {
            $ingridients_reagent = array_keys( $reagent );
            shuffle( $ingridients_reagent );
            $ingridients_reagent = array_slice( $ingridients_reagent, mt_rand( 0, ceil(count($ingridients_reagent)/2) ), mt_rand( 2, 5 ) );
            //$ingridients_reagent[] = 719;

            cache::clean( 'spr-recipe' );
            $reactiv_menu   = $_recipes->get_raw();

            if( mt_rand( 0, 100 ) > 35 )
            {
                $ingridients_reaktiv = array();
            }
            else
            {
                $ingridients_reaktiv = array_keys( $reactiv_menu );
                shuffle( $ingridients_reaktiv );
                $ingridients_reaktiv = array_slice( $ingridients_reaktiv, mt_rand( 0, ceil(count($ingridients_reaktiv)/2) ), mt_rand( 1, 3 ) );
            }

            $data = array
            (
                'id' => 0,
                'name' => 'Тестовий розчин '.$I,
                'comment' => '"Тестовий розчин '.$I.'" створений автоматично',
                'units_id' => 1,
                'ingredients_reagent' => $ingridients_reagent,
                'ingredients_reactiv' => $ingridients_reaktiv,
            );

            $_recipes->save( 0, $data );
            $I++;
        }
    }

    public final function create_reagent()
    {
        $spr = new spr_manager( 'reagent' );
        $N = 10;

        foreach
        (
            array
            (
                array( 'name' => 'Тестова речовина (liquid)', 'units_id' => 1 ),
                array( 'name' => 'Тестова речовина (solid)',  'units_id' => 2 ),
                array( 'name' => 'Тестова речовина (powder)', 'units_id' => 2 ),
                array( 'name' => 'Тестовий матеріал (other)',  'units_id' => 9 ),
            ) as $code
        )
        {
            for( $i = 1; $i <= $N; $i++ )
            {
                $spr->save( 0, array( 'name' => $code['name'].' '.$i, 'units_id' => $code['units_id'] ) );
            }

        }

    }




}