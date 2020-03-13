<?php

//////////////////////////////////////////////////////////////////////////////////////////

if( !defined('MRGAUSS') ){ echo basename(__FILE__); exit; }

//////////////////////////////////////////////////////////////////////////////////////////


$tpl->ins( 'main', '
                    <div id="shkurdoda_frame">
                        <div id="color_changer">
                            <input type="range" min="0" max="360" value="0">
                        </div>
                        <img src="/res/img/pink_shkurdoda.jpg" alt="" />
                        <img id="shkurdoda_frame_mask" src="/res/img/pink_shkurdoda_mask.png" alt="" />
                    </div>
                    ' );
