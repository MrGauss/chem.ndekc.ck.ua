<!DOCTYPE HTML>
<html lang="ua">
    <!-- Використано RAM:         {user_memory} -->
    <!-- Запитів до БД:           {queries} -->
    <!--    з них поміщено в кеш: {queries_cached} -->
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset={charset}" />
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=2">
        <meta name="mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <link rel="manifest" href="/manifest.json">
        <meta name="description" content="ЕКСПЕРТНА СЛУЖБА МВС УКРАЇНИ">
        <meta name="keywords" content="Експертна служба">
        <meta name="author" content="MrGauss">
        <meta name="application-name" content="ExpertCMS">
        <meta charset="{charset}">

    	<base href="{HOME}">
    	<title>ЕКСПЕРТНА СЛУЖБА МВС УКРАЇНИ</title>

        <link rel="stylesheet" type="text/css" href="{SKINDIR}/css/jquery.css?v=2" media="screen" />
        <link rel="stylesheet" type="text/css" href="{SKINDIR}/css/style.css?v=3" media="screen" />
        [login][mod:{MOD}]<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/chem.{MOD}.css?rand={RAND}" media="screen" />[/mod][/login]
        <script src="{SKINDIR}/js/jquery.js" type="text/javascript"></script>
        [login]<script src="{SKINDIR}/js/jquery.mask.js" type="text/javascript"></script>[/login]
        [login]<script src="{SKINDIR}/js/jquery.scrollTo.min.js" type="text/javascript"></script>[/login]
        [login]<script src="{SKINDIR}/js/jquery-ui.js" type="text/javascript"></script>[/login]
        <script src="{SKINDIR}/js/window_resize.js" type="text/javascript"></script>
        [login]<script src="{SKINDIR}/js/main.js?rand={RAND}" type="text/javascript"></script>[/login]
        [login]<script src="{SKINDIR}/js/autocomplete.js?rand={RAND}" type="text/javascript"></script>[/login]
        [login][mod:{MOD}]<script src="{SKINDIR}/js/chem.{MOD}.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]

        [login][mod:spr_clearence]<script src="{SKINDIR}/js/chem.spr_manager.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]
        [login][mod:spr_dangerous]<script src="{SKINDIR}/js/chem.spr_manager.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]
        [login][mod:spr_reactives]<script src="{SKINDIR}/js/chem.spr_manager.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]
        [login][mod:spr_states]<script src="{SKINDIR}/js/chem.spr_manager.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]
        [login][mod:spr_purpose]<script src="{SKINDIR}/js/chem.spr_manager.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]
        [login][mod:spr_units]<script src="{SKINDIR}/js/chem.spr_manager.js?rand={RAND}" type="text/javascript"></script>[/mod][/login]

    </head>
    <body class="[nologin]nologin[/nologin] [login]w_600_min bg_noimage[/login]" data-mod="{MOD}" data-rand="{RAND}" data-region_id="{CURRENT_REGION_ID}" data-user="{CURRENT_USER_LOGIN}" [access:chat:view]data-allow_chat="1"[/access]>

        <div id="err" class="info">
            <div class="box">
                <div class="title">{info:title}</div>
                <div class="message"><pre>{info:message}</pre></div>
                <div class="close" data-role="close">Зрозуміло</div>
            </div>
        </div>

        {global:info}
        <div id="main_frame" class="wpage">
            [login]
            <div id="page_frame">
                <div id="head" class="wpage">
                    [access:chat:view]<a data-unread="{CURRENT_UNREAD_MESSAGES}" class="new_messages" href="/index.php?mod=chat">[нові повідомлення]</a>[/access]

                    <a data-role="home" href="/">Головна</a>
                    [modinfo]<a data-role="modinfo" href="{mod:link}">{mod:name}</a>[/modinfo]
                    <a data-role="user" href="/">{user:surname} {user:name} {user:phname}</a>
                    <a data-role="logout" href="/index.php?mod=logout">Вихід</a>

                    <div class="clear"></div>
                </div>
                <div id="content" class="wpage">
                    {global:main}
                    <div class="clear"></div>
                </div>
                <div id="foot" class="wpage">
                    <span>&bull;</span>
                    <span class="foot_logo_name">Експертна служба МВС України</span>
                    <span>&bull;</span>
                    <div class="clear"></div>
                </div>
            </div>
            [/login]
            [nologin]{global:login}[/nologin]
        </div>
        <div id="ajax"></div>
    </body>
</html>