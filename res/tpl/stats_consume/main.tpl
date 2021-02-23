<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/highcharts/highcharts.css" media="screen" />
<link rel="stylesheet" type="text/css" href="{SKINDIR}/css/highcharts/themes/grid-light.css" media="screen" />
<script src="{SKINDIR}/js/highcharts/highcharts.js" type="text/javascript"></script>
<script src="{SKINDIR}/js/highcharts/modules/item-series.js" type="text/javascript"></script>

<div id="list_frame" class="stats">

    <div id="filters" class="filters">
        <form action="" method="post">
            <table class="filters_header_frame">
                <tr>
                    <td class="create_button"><button id="clear" type="reset" data-id="0">�������</button></td>
                    <td class="filters_area">
                        <div class="filters_list">

                            <div class="fbox">
                                <div class="filter">
                                    <label class="label">���� ������������ (��)</label>
                                    <input class="input" type="text" autocomplete="off" name="consume_date[]" value="{consume_date:from}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
                                </div>
                                <div class="filter">
                                    <label class="label">���� ������������ (��)</label>
                                    <input class="input" type="text" autocomplete="off" name="consume_date[]" value="{consume_date:to}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
                                </div>
                                <div class="clear"></div>
                            </div>

                            <div class="fbox">

                                <div class="filter ch_filter">
                                    <input  id="filter-is_precursor" class="input" data-group="is_precursor" data-role="filter" type="checkbox" name="is_precursor" value="1" {is_precursor}>
                                    <label for="filter-is_precursor" class="label">���� ����������</label>
                                </div>

                            </div>

                        </div>
                    </td>
                    <td class="search_button"><button id="search" type="submit">���������</button></td>
                </tr>
            </table>
        </form>
    </div>

    <div id="list" class="list">

        <div class="block_info great">
            <p>���������� ��� ������ �� <b>"(�� �����)"</b> ���������� ����� ����������������� �������.</p>
            <p>���, �� �� ����� ���� ������, ���������� �� ������� ����.</p>
        </div>

        <h2>���������� ������������ �������� (�������)</h2>
        <div id="table02chart"></div>
        <table id="table02" class="stats_table stats_by_purpose_id">
            <thead>
                <tr class="head">
                    <th class="noselect reagent_name" data-sorter="1" data-type="txt" data-sort="reagent_name" colspan="2">����� �������� �� ���������� ��������</th>
                    <th class="noselect stock_quantity_inc" data-sorter="1" data-type="int" data-sort="stock_quantity_inc">������� �� �����</th>
                    <th class="noselect stock_quantity_left" data-sorter="1" data-type="int" data-sort="stock_quantity_left">���������� �� �����</th>
                    <th class="noselect dispersion_quantity_inc" data-sorter="1" data-type="int" data-sort="dispersion_quantity_inc">������ � ����������</th>
                    <th class="noselect dispersion_quantity_left" data-sorter="1" data-type="int" data-sort="dispersion_quantity_left">���������� � ���������</th>
                    <th class="noselect consume_quantity" data-sorter="1" data-type="int" data-sort="consume_quantity_full">�����������<br>������</th>
                    <th class="noselect consume_quantity" data-sorter="1" data-type="int" data-sort="consume_quantity">�����������<br>(�� �����)</th>

                    <th class="noselect consume_count" data-sorter="1" data-type="int" data-sort="consume_count">�����������<br>(�� �����)</th>
                </tr>
            </thead>
            <tbody>
            {table02}
            </tbody>
        </table>

        <table id="table01" class="stats_table stats_by_stock_id">
            <caption>���������� ������������ �������� � ������</caption>
            <thead>
                <tr class="head">
                    <th class="noselect reagent_name" data-sorter="1" data-type="txt" data-sort="reagent_name" colspan="3">����� �������� �� ���������� ��������</th>
                    <th class="noselect stock_quantity_inc" data-sorter="1" data-type="int" data-sort="stock_quantity_inc">������� �� �����</th>
                    <th class="noselect stock_quantity_left" data-sorter="1" data-type="int" data-sort="stock_quantity_left">���������� �� �����</th>
                    <th class="noselect dispersion_quantity_inc" data-sorter="1" data-type="int" data-sort="dispersion_quantity_inc">������ � ����������</th>
                    <th class="noselect dispersion_quantity_left" data-sorter="1" data-type="int" data-sort="dispersion_quantity_left">���������� � ���������</th>
                    <th class="noselect consume_quantity" data-sorter="1" data-type="int" data-sort="consume_quantity_full">�����������<br>������</th>
                    <th class="noselect consume_quantity" data-sorter="1" data-type="int" data-sort="consume_quantity">�����������<br>(�� �����)</th>

                    <th class="noselect consume_count" data-sorter="1" data-type="int" data-sort="consume_count">�����������<br>(�� �����)</th>
                </tr>
            </thead>
            <tbody>
            {table01}
            </tbody>
        </table>

        <h2>���������� ������������ �������� �� �������������</h2>

        <div id="table03chart"></div>

        <table id="table03" class="stats_table stats_by_stock_id">
            <thead>
                <tr class="head">
                    <th class="noselect purpose_name" colspan="1">���� ������������ (�����������)</th>
                    <th class="noselect reagent_name" colspan="2">����� �������� �� ���������� ��������</th>
                    <th class="noselect consume_count">�����������</th>
                    <th class="noselect consume_quantity">�������� �����������</th>
                </tr>
            </thead>
            {table03}
        </table>




    </div>
</div>

