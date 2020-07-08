<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/highcharts/highcharts.css" media="screen" />
<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/highcharts/themes/grid-light.css" media="screen" />
<script src="{SKINDIR}/js/highcharts/highcharts.js" type="text/javascript"></script>

<div id="list_frame" class="stats stats_dynamic">

    <div id="filters" class="filters">
        <form action="" method="post">
            <table class="filters_header_frame">
                <tr>
                    <td class="create_button"><button id="clear" type="reset" data-id="0">�������</button></td>
                    <td class="filters_area">
                        <div class="filters_list">



                        </div>
                    </td>
                    <td class="search_button"><button id="search" type="submit">���������</button></td>
                </tr>
            </table>
        </form>
    </div>

    <div id="list" class="list">

        <div class="block_info great">
            <p>��������� � ����� ����� ��������� �� <u>�������������</u> ������������ �����.</p>
            <p>�����, ������� �������� �� ��������, �� ����������� �������� ������ ������������ ���� ���������� �� 100%.</p>
            <p>� ���������� ������������ �������� ������������ �������� �� �������� � �������� �� �������� �������.</p>
            <p><i>���������: ���� �� �� ���� ����������� 1000�� �������� � ��� �������� ������� ����������� 200��, �� �� �������� ����������� 20% �� �������� ������� ������������� ��������.</i></p>
            <p>����������� ��������� ��� ���������� �������� ��������� � ����� ������� ���������� ��� ��������� �� ���������� ���������.</p>
        </div>

        <h2>������� ������������ �������� �� ��������� ��������</h2>
        <h3>�� ������� �� �������� ����</h3>
        <div id="compare_chart"></div>

        <h2>г����� ������������ �������� �� ��������� ��������</h2>
        <h3>�� ������� �� �������� ������</h3>
        <div id="compare_diff_chart"></div>

        <h2>������� ������������ �������� �� ��������� ��������</h2>
        <h3>�� �������� ��</h3>

        <div id="table01_chart"></div>
        <div data-role="show_or_hide" data-content_id="table01" class="show_hide noselect"><b>�������� / ������� ������� �������</b></div>

        <table id="table01" class="stats_table stats_by_purpose_id dnone">
            <thead>
                <tr class="head">
                    <th class="noselect name"                   colspan="2"  rowspan="2">����� �������� �� ���������� ��������</th>
                    <th class="noselect consume_quantity_month" colspan="12" rowspan="1">�������� ������������</th>
                    <th class="consume_quantity" rowspan="2">������</th>
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

        <h2>������� ������������ �������� �� ��������� ��������</h2>
        <h3>�� ������� ��</h3>

        <div id="table02_chart"></div>
        <div data-role="show_or_hide" data-content_id="table02" class="show_hide noselect"><b>�������� / ������� ������� �������</b></div>
        <table id="table02" class="stats_table stats_by_purpose_id dnone">
            <thead>
                <tr class="head">
                    <th class="noselect name"                   colspan="2"  rowspan="2">����� �������� �� ���������� ��������</th>
                    <th class="noselect consume_quantity_month" colspan="12" rowspan="1">�������� ������������</th>
                    <th class="consume_quantity" rowspan="2">������</th>
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

