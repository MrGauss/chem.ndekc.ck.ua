<?php

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

$db = new db
(
  '127.0.0.1',   // HOST
  '15472',   // HOST
  'chem.ndekc.ck.ua',   // DBNAME
  'chem.ndekc.ck.ua',   // DBUSER
  '$chem.ndekc.ck.ua%', // DBPASS
  'public',        // SCHEMA
  CHARSET,      // CHARSET
  'WIN1251'      // COLLATE
);