<!DOCTYPE HTML>
<html lang="ua">
    <!-- Використано RAM:         {user_memory} -->
    <!-- Запитів до БД:           {queries} -->
    <!--    з них поміщено в кеш: {queries_cached} -->
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=CP1251" />
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=2">
        <meta name="mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <link rel="manifest" href="/manifest.json">
        <meta name="description" content="ЕКСПЕРТНА СЛУЖБА МВС УКРАЇНИ">
        <meta name="keywords" content="Експертна служба">
        <meta name="author" content="MrGauss">
        <meta name="application-name" content="ExpertCMS">
        <meta charset="CP1251">

    	<base href="https://chem.ndekc.ck.ua/">
    	<title>ЕКСПЕРТНА СЛУЖБА МВС УКРАЇНИ</title>

        <style media="screen" type="text/css">
            article,aside,figcaption,figure,footer,header,main,hgroup,nav,section,time,ul,ol,h1,h2,h3{ display: block; -moz-box-sizing: border-box; box-sizing: border-box; -webkit-box-sizing: border-box; }
            html,body,div,main,ul,ol,li,dl,dt,dd,h1,h2,h3,h4,h5,h6,pre,form,p,blockquote,fieldset,input,textarea,span{margin: 0; padding: 0; -moz-box-sizing: border-box; box-sizing: border-box; }
            table, tr, tr{ -moz-box-sizing: border-box; box-sizing: border-box; -webkit-box-sizing: border-box; }
            input, textarea, select, button, body{  }
            body{ color: #222222; background: #FFFFFF; padding: 20mm; font-size: 11pt; }
            *{
                font-kerning: normal;
                -webkit-font-kerning: normal;
                -webkit-hyphens: auto;
                -moz-hyphens: auto;
                -ms-hyphens: auto;
                hyphens: auto;
                z-index: : 1;
             }

            a, select, option{ cursor: pointer; }

            ul.reset{ list-style: none; }

            a:link, a:visited, .anim
            {
                -webkit-transition: color 0.2s ease, background 0.2s ease;
                -moz-transition: color 0.2s ease, background 0.2s ease;
                -ms-transition: color 0.2s ease, background 0.2s ease;
                -o-transition: color 0.2s ease, background 0.2s ease;
                transition: color 0.2s ease, background 0.2s ease;
            }

            a:link, a:visited
            {
                color: #398dd8;
                text-decoration: none;
            }

            a:hover
            {
                text-decoration: none;
            }
            a:active{ outline: none; }

            a img  { border: 0 none; }
            .clear{ clear: both; }
            .w_600_min{ min-width: 600px; }
            .bg_noimage{ background-image: none; }
            .dnone{ display: none; }
            .center{ text-align: center; }

            input:disabled{ cursor: not-allowed; }

            input::-moz-focus-inner{border:0;padding:0;}
            button::-moz-focus-inner{border:0;padding:0;}
            select::-moz-focus-inner{border:0;padding:0;}
            textarea::-moz-focus-inner{border:0;padding:0;}
            option::-moz-focus-inner{border:0;padding:0;}

            /*********************************/

            table.data{ width: 100%; margin: 0px auto 0px auto; border: 1px solid rgba(17, 17, 17, 1); border-collapse: collapse; }
            table.data th,
            table.data td{ width: auto; border: 1px solid rgba(17, 17, 17, 1); border-collapse: collapse; padding: 1mm; }
            table.data td.numi{ width: 5%; text-align: center; }
            table.data td.hash{ width: 7%; text-align: center; font-family: "Courier New", Courier, monospace; font-size: 10pt; text-transform: uppercase; }
            table.data td.using_date{ width: 10%; text-align: center; }
            table.data td.purpose_name{ width: 10%; text-align: center; }
            table.data td.purpose_info{ width: 13%; text-align: center; }
            table.data td.expert{ width: 20%; text-align: center; }
            table.data td.consume{ width: auto; text-align: left; }

            table.data td               div.fxw{ overflow: hidden; word-wrap: break-word; }
            table.data td.numi          div.fxw{ text-align: center; }
            table.data td.hash          div.fxw{ text-align: center; }
            table.data td.using_date    div.fxw{ text-align: center; }
            table.data td.purpose_name  div.fxw{ text-align: center; }
            table.data td.purpose_info  div.fxw{ text-align: center; }
            table.data td.expert        div.fxw{ text-align: center; }
            table.data td.consume       div.fxw{ text-align: left; }

            table.data td.consume .consume_elem{ display: block; padding: 1mm 0px 1mm 0px; margin: 0mm 2mm 0mm 2mm; border-bottom: 1px dashed rgba(34, 34, 34, 1); }
            table.data td.consume .consume_elem:last-of-type{ border-bottom: none; }

            table.data th{ text-align: center; padding: 6mm 0mm 6mm 0mm; background: rgba(204, 204, 204, 1); font-weight: bold; }
        </style>
    </head>
    <body data-mod="{MOD}" data-rand="{RAND}" data-region_id="{CURRENT_REGION_ID}" data-user="{CURRENT_USER_LOGIN}">
        <table class="data" border="1" style="border-collapse: collapse; border-color: rgba(0, 0, 0, 1); border-width: 3px;">
        <tr>
            <th class="numi"><div class="fxw">№<br>п/п</div></th>
            <th class="hash"><div class="fxw">Хеш<br>запису</div></th>
            <th class="using_date"><div class="fxw">Дата</div></th>
            <th class="purpose_name"><div class="fxw">Мета</div></th>
            <th class="purpose_info"><div class="fxw">Куди<br>використано</div></th>
            <th class="expert"><div class="fxw">Хто<br>використав</div></th>
            <th class="consume"><div class="fxw">Що<br>використано</div></th>
        </tr>
            {list}
        </table>
    </body>
</html>