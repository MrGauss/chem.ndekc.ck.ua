<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }
if( !defined('_MOD_NAME_') ){ define('_MOD_NAME_', 'Пофарбуй Шкурдоду' ); }

access::check( 'shkurdoda', 'view' );

//////////////////////////////////////////////////////////////////////////////////////////


$tpl->ins( 'main', '
                    <div id="shkurdoda_frame">
                        <div id="color_changer">
                            <input class="layer2" type="range" min="0" max="360" value="0" name="hue-rotate">
                            <br>
                            <input class="layer2" type="range" min="0" max="200" value="100" name="saturate">
                            <br>
                            <input class="layer3" type="range" min="0" max="360" value="0" name="hue-rotate">
                            <br>
                            <input class="layer3" type="range" min="0" max="200" value="100" name="saturate">
                            <br>
                        </div>
                        <div class="layer layer01"><img src="/res/img/pink_shkurdoda.jpg" alt="" /></div>
                        <div class="layer layer02"><img id="shkurdoda_frame_mask" src="/res/img/pink_shkurdoda_mask.png" alt="" /></div>
                        <div class="layer layer03"><img id="shkurdoda_frame_mask2" src="/res/img/pink_shkurdoda_mask_3.png" alt="" /></div>
                    </div>
                    ' );
