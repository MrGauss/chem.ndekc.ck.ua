<div id="list_frame" class="dispersion">
    
    <div id="filters" class="filters">
        <table class="filters_header_frame">
            <tr>
                <td class="create_button"><button id="create" type="button" data-id="0">Створити</button></td>
                <td class="filters_area">
                    <div class="filters_list">

                        <div class="fbox">
                            <div class="filter">
                                <label class="label">Назва</label>
                                <select class="input select" data-value="0" value="0" name="reagent_id" data-role="filter"><option value="0">--</option>{select:reagent}</select>
                            </div>
                            <div class="filter">
                                <label class="label">Клас небезпеки</label>
                                <select class="input select" data-value="0" value="0" name="danger_class_id" data-role="filter"><option value="0">--</option>{select:danger_class}</select>
                            </div>
                            <div class="clear"></div>
                        </div>
                        <div class="fbox">
                            <div class="filter ch_filter">
                                <input  id="filter-is_dead_1" class="input" data-group="is_dead" data-role="filter" type="checkbox" name="is_dead" value="1">
                                <label for="filter-is_dead_1" class="label">Лише зіпсовані</label>
                            </div>

                            <div class="filter ch_filter">
                                <input  id="filter-is_dead_0" class="input" data-group="is_dead" data-role="filter" type="checkbox" name="is_dead" value="0" checked="checked">
                                <label for="filter-is_dead_0" class="label">Лише не зіпсовані</label>
                            </div>

                            <div class="filter ch_filter">
                                <input  id="filter-quantity_left" class="input" data-group="quantity_left" data-role="filter" type="checkbox" name="quantity_left" value="0">
                                <label for="filter-quantity_left" class="label">Лише використані</label>
                            </div>

                            <div class="filter ch_filter">
                                <input  id="filter-quantity_left_more" class="input" data-group="quantity_left" data-role="filter" type="checkbox" name="quantity_left:more" value="0" checked="checked">
                                <label for="filter-quantity_left_more" class="label">Лише не використані</label>
                            </div>
                            <div class="clear"></div>
                        </div>

                    </div>
                </td>
                <td class="search_button"><button id="search" type="button">Шукати</button></td>
            </tr>
        </table>
    </div>

    <div class="line header">
        <table>
            <tr>
                <td class="numi">&nbsp;</td>
                <td class="reagent"             data-sorter="1" data-type="txt" data-sort="reagent">Назва</td>
                <td class="number"              data-sorter="1" data-type="txt" data-sort="number">Номер</td>
                <td class="inc_date"            data-sorter="1" data-type="int" data-sort="inc_date">Дата видачі</td>
                <td class="quantity_inc"        data-sorter="1" data-type="int" data-sort="quantity_inc">Видано</td>
                <td class="quantity_left"       data-sorter="1" data-type="int" data-sort="quantity_left">Залишилось</td>
                <td class="out_expert"          data-sorter="1" data-type="txt" data-sort="out_expert">Отримав</td>
                <td></td>
            </tr>
        </table>
    </div>

    <div id="list" class="list">
        {list}
    </div>
</div>

