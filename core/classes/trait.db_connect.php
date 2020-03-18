<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

trait db_connect
{
	private $db = false;
	
	public function __construct()
	{
		$this->__cconnect_2_db();
	}
	
	private function __cconnect_2_db()
	{
		global $db;
		$this->db = &$db;
	}


    /*private final function get_table_info()
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
    }*/

}

