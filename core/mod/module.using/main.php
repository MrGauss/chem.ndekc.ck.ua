<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////

access::check( 'using', 'view' ); 

$tpl->load( 'using/main' );

$tpl->set( '{list}', (new using)->get_html( array(), 'using/line' ) );

$tpl->compile( 'using/main' );

$tpl->ins( 'main', $tpl->result( 'using/main' ) );
$tpl->clean( 'using/main' );