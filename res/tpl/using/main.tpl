<div id="list_frame" class="using">

    <div id="filters" class="filters">
        <table class="filters_header_frame">
            <tr>
                <td class="create_button"><button id="create" type="button" data-hash="">��������</button></td>
                <td class="filters_area">
                    <div class="filters_list">

                        <div class="fbox">
                            <div class="filter">
                                <label class="label">�������� / �������</label>
                                <select class="input select" data-value="{filter:reagent_id}" value="{filter:reagent_id}" name="reagent_id" data-role="filter"><option value="0">--</option>{select:reagent}</select>
                            </div>
                            <div class="clear"></div>
                        </div>

                        <div class="fbox">
                            <div class="filter">
                                <label class="label">���� ������������ (��)</label>
                                <input type="text" class="input select" name="using_date_from" data-role="filter" data-value="{filter:using_date_from}" value="{filter:using_date_from}" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" data-mindate="-10y" data-maxdate="+10y" maxlength="10">
                            </div>
                            <div class="filter">
                                <label class="label">���� ������������ (��)</label>
                                <input type="text" class="input select" name="using_date_to" data-role="filter" data-value="{filter:using_date_to}" value="{filter:using_date_to}" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" data-mindate="-10y" data-maxdate="+10y" maxlength="10">
                            </div>
                            <div class="clear"></div>
                        </div>

                        <div class="fbox">
                            <div class="filter">
                                <label class="label">���� ������������</label>
                                <select class="input select" data-value="{filter:purpose_id}" value="{filter:purpose_id}" name="purpose_id" data-role="filter"><option value="0">--</option>{select:purpose}</select>
                            </div>
                            <div class="filter">
                                <label class="label">��� ����������</label>
                                <select class="input select" data-value="{filter:expert_id}" value="{filter:expert_id}" name="expert_id" data-role="filter"><option value="0">--</option>{select:user}</select>
                            </div>
                            <div class="clear"></div>
                        </div>

                    </div>
                </td>
                <td class="search_button">
                    <button id="search" type="button">������</button>
                    <button id="print" type="button">����</button>
                </td>
            </tr>
        </table>
    </div>

    <div class="line header">
        <table>
            <tr>
                <td class="numi">&nbsp;</td>
                <td class="date"            data-sorter="1" data-type="int" data-sort="date">����</td>
                <td class="purpose_name"    data-sorter="1" data-type="int" data-sort="purpose_id">���� ������������</td>
                <td class="name"            data-sorter="1" data-type="txt" data-sort="result">��������� ������������</td>
                <td class="expert"          data-sorter="1" data-type="txt" data-sort="expert">��� ����������</td>
                <td class="consume">�� �����������</td>
                <td></td>
            </tr>
        </table>
    </div>

    <div id="list" class="list">

        {list}

    </div>
</div>

