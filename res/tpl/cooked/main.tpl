<div id="list_frame" class="spr_reactives">

    <div id="filters" class="filters">
        <table class="filters_header_frame">
            <tr>
                <td class="create_button"><button id="create" type="button" data-hash="">��������</button></td>
                <td class="filters_area">
                    <div class="filters_list">

                        <div class="fbox">
                            <div class="filter ch_filter">
                                <input  id="filter-is_dead_1" class="input" data-group="is_dead" data-role="filter" type="checkbox" name="is_dead" value="1">
                                <label for="filter-is_dead_1" class="label">���� �������</label>
                            </div>

                            <div class="filter ch_filter">
                                <input  id="filter-is_dead_0" class="input" data-group="is_dead" data-role="filter" type="checkbox" name="is_dead" value="0" >
                                <label for="filter-is_dead_0" class="label">���� �� �������</label>
                            </div>

                            <div class="filter ch_filter">
                                <input  id="filter-quantity_left" class="input" data-group="quantity_left" data-role="filter" type="checkbox" name="quantity_left" value="0">
                                <label for="filter-quantity_left" class="label">���� ����������</label>
                            </div>

                            <div class="filter ch_filter">
                                <input  id="filter-quantity_left_more" class="input" data-group="quantity_left" data-role="filter" type="checkbox" name="quantity_left:more" value="0" >
                                <label for="filter-quantity_left_more" class="label">���� �� ����������</label>
                            </div>
                            <div class="clear"></div>
                        </div>

                    </div>
                </td>
                <td class="search_button"><button id="search" type="button">������</button></td>
            </tr>
        </table>
    </div>

    <div class="line header">
        <table>
            <tr>
                <td class="numi">&nbsp;</td>
                <td class="name"          data-sorter="1" data-type="txt" data-sort="reagent">�����</td>
                <td class="inc_date"      data-sorter="1" data-type="int" data-sort="inc_date">���� ������������</td>
                <td class="dead_date"     data-sorter="1" data-type="int" data-sort="dead_date">ʳ����� ����</td>
                <td class="quantity_inc"  data-sorter="1" data-type="int" data-sort="quantity_inc">����������� �������</td>
                <td class="quantity_left" data-sorter="1" data-type="int" data-sort="quantity_left">����������</td>
                <td class="coocked_by"    data-sorter="1" data-type="txt" data-sort="quantity_left">��� �������</td>
                <td class="composition">�����</td>
            </tr>
        </table>
    </div>

    <div id="list" class="list">
        {list}
    </div>
</div>

