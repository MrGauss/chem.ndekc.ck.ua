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

                        </div>
                    </td>
                    <td class="search_button"><button id="search" type="submit">���������</button></td>
                </tr>
            </table>
        </form>
    </div>

    <div id="list" class="list">

        <h2 id="table02">���������� ������������ ��������</h2>
        <table class="stats_table stats_by_purpose_id">
            <tr class="head">
                <th class="noselect reagent_name" data-sorter="1" data-type="txt" data-sort="reagent_name" colspan="2">����� �������</th>
                <th class="noselect reactiv_quantity_inc" data-sorter="1" data-type="int" data-sort="reactiv_quantity_inc">��������</th>
                <th class="noselect reactiv_quantity_left" data-sorter="1" data-type="int" data-sort="reactiv_quantity_left">���������� � ���������</th>
                <th class="noselect consume_quantity" data-sorter="1" data-type="int" data-sort="consume_quantity">�������� �����������</th>
            </tr>
            {table02}
        </table>





    </div>
</div>

