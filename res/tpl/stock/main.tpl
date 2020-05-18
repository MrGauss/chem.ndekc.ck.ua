<div id="list_frame" class="stock">

    <div id="filters" class="filters">
        <table class="filters_header_frame">
            <tr>
                <td class="create_button"><button id="create" type="button" data-id="0">Створити</button></td>
                <td class="filters_area">
                    <div class="filters_list">

                        <div class="fbox">
                            <div class="filter">
                                <label class="label">Назва</label>
                                <select class="input select" data-value="0" value="0" name="reagent_id" data-filter="1"><option value="0">--</option>{select:reagent}</select>
                            </div>
                            <div class="filter">
                                <label class="label">Клас небезпеки</label>
                                <select class="input select" data-value="0" value="0" name="danger_class_id" data-filter="1"><option value="0">--</option>{select:danger_class}</select>
                            </div>
                            <div class="clear"></div>
                        </div>
                        <div class="fbox">
                            <div class="filter fullheight">
                                some shit
                            </div>
                            <div class="clear"></div>
                        </div>

                    </div>
                </td>
                <td class="search_button"><button id="search" type="button">Шукати</button></td>
            </tr>
        </table>
    </div>

    <div id="table_header" class="line header">
        <table>
            <tr>
                <td class="numi">&nbsp;</td>
                <td class="reagent"             data-sorter="1" data-type="txt" data-sort="reagent">Назва</td>
                <td class="number"              data-sorter="1" data-type="txt" data-sort="number">Номер</td>
                <td class="inc_date"            data-sorter="1" data-type="int" data-sort="inc_date">Дата надходження</td>
                <td class="quantity_inc"        data-sorter="1" data-type="int" data-sort="quantity_inc">Надійшло</td>
                <td class="quantity_left"       data-sorter="1" data-type="int" data-sort="quantity_left">На складі</td>
                <td class="quantity_dispersed"  data-sorter="1" data-type="int" data-sort="quantity_dispersed">Видано</td>
                <td class="quantity_not_used"   data-sorter="1" data-type="int" data-sort="quantity_not_used">Використано</td>
                <td class="dead_date"           data-sorter="1" data-type="int" data-sort="dead_date">Кінцева дата</td>
                <td></td>
            </tr>
        </table>
    </div>

    <div id="list" class="list">
        {list}
    </div>
</div>

