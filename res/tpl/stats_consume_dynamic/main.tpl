<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/highcharts/highcharts.css" media="screen" />
<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/highcharts/themes/grid-light.css" media="screen" />
<script src="{SKINDIR}/js/highcharts/highcharts.js" type="text/javascript"></script>

<div id="list_frame" class="stats stats_dynamic">

    <div id="filters" class="filters">
        <form action="" method="post">
            <table class="filters_header_frame">
                <tr>
                    <td class="create_button"><button id="clear" type="reset" data-id="0">Скинути</button></td>
                    <td class="filters_area">
                        <div class="filters_list">



                        </div>
                    </td>
                    <td class="search_button"><button id="search" type="submit">Формувати</button></td>
                </tr>
            </table>
        </form>
    </div>

    <div id="list" class="list">

        <div class="block_info great">
            <p>Показники в цьому розділі побудовані на <u>нормалізованих</u> статистичних даних.</p>
            <p>Тобто, кількість реактиву чи матеріалу, що використана протягом одного календарного року приймається за 100%.</p>
            <p>В подальшому вираховується щомісячне використання реактиву чи матеріалу в відсотках від загальної кількості.</p>
            <p><i>Наприклад: якщо за рік було використано 1000мл реактиву з них протягом березня використано 200мл, то за березень використано 20% від загальної кількості використаного реактиву.</i></p>
            <p>Нормалізація необхідна для приведення кількісних показників в єдину систему вимірювання для можливості їх подальшого порівняння.</p>
        </div>

        <h2>Динаміка використання реактивів та розхідних матеріалів</h2>
        <h3>за минулий та поточний роки</h3>
        <div id="compare_chart"></div>

        <h2>Різниця використання реактивів та розхідних матеріалів</h2>
        <h3>між минулим та поточним роками</h3>
        <div id="compare_diff_chart"></div>

        <h2>Динаміка використання реактивів та розхідних матеріалів</h2>
        <h3>за поточний рік</h3>

        <div id="table01_chart"></div>
        <div data-role="show_or_hide" data-content_id="table01" class="show_hide noselect"><b>Показати / сховати таблицю значень</b></div>

        <table id="table01" class="stats_table stats_by_purpose_id dnone">
            <thead>
                <tr class="head">
                    <th class="noselect name"                   colspan="2"  rowspan="2">Назва реактиву чи витратного матеріалу</th>
                    <th class="noselect consume_quantity_month" colspan="12" rowspan="1">Помісячне використання</th>
                    <th class="consume_quantity" rowspan="2">Всього</th>
                </tr>
                <tr class="head">
                    <th class="month01">01</th>
                    <th class="month02">02</th>
                    <th class="month03">03</th>
                    <th class="month04">04</th>
                    <th class="month05">05</th>
                    <th class="month06">06</th>
                    <th class="month07">07</th>
                    <th class="month08">08</th>
                    <th class="month09">09</th>
                    <th class="month10">10</th>
                    <th class="month11">11</th>
                    <th class="month12">12</th>
                </tr>
            </thead>
            <tbody>
                {table01}
            </tbody>
        </table>

        <h2>Динаміка використання реактивів та розхідних матеріалів</h2>
        <h3>за минулий рік</h3>

        <div id="table02_chart"></div>
        <div data-role="show_or_hide" data-content_id="table02" class="show_hide noselect"><b>Показати / сховати таблицю значень</b></div>
        <table id="table02" class="stats_table stats_by_purpose_id dnone">
            <thead>
                <tr class="head">
                    <th class="noselect name"                   colspan="2"  rowspan="2">Назва реактиву чи витратного матеріалу</th>
                    <th class="noselect consume_quantity_month" colspan="12" rowspan="1">Помісячне використання</th>
                    <th class="consume_quantity" rowspan="2">Всього</th>
                </tr>
                <tr class="head">
                    <th class="month01">01</th>
                    <th class="month02">02</th>
                    <th class="month03">03</th>
                    <th class="month04">04</th>
                    <th class="month05">05</th>
                    <th class="month06">06</th>
                    <th class="month07">07</th>
                    <th class="month08">08</th>
                    <th class="month09">09</th>
                    <th class="month10">10</th>
                    <th class="month11">11</th>
                    <th class="month12">12</th>
                </tr>
            </thead>
            <tbody>
                {table02}
            </tbody>
        </table>

    </div>
</div>

