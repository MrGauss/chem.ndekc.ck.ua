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
}

