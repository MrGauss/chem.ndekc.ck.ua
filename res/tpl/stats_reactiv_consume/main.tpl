<div id="list_frame" class="stats">

    <div id="filters" class="filters">
        <form action="" method="post">
            <table class="filters_header_frame">
                <tr>
                    <td class="create_button"><button id="clear" type="reset" data-id="0">Скинути</button></td>
                    <td class="filters_area">
                        <div class="filters_list">

                            <div class="fbox">
                                <div class="filter">
                                    <label class="label">Дата використання (від)</label>
                                    <input class="input" type="text" autocomplete="off" name="consume_date[]" value="{consume_date:from}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
                                </div>
                                <div class="filter">
                                    <label class="label">Дата використання (до)</label>
                                    <input class="input" type="text" autocomplete="off" name="consume_date[]" value="{consume_date:to}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
                                </div>
                                <div class="clear"></div>
                            </div>

                        </div>
                    </td>
                    <td class="search_button"><button id="search" type="submit">Формувати</button></td>
                </tr>
            </table>
        </form>
    </div>

    <div id="list" class="list">

        <table class="stats_table stats_by_purpose_id">
            <caption>Статистика використання розчинів</caption>
            <tr class="head">
                <th class="noselect reagent_name" data-sorter="1" data-type="txt" data-sort="reagent_name" colspan="2">Назва розчину</th>
                <th class="noselect reactiv_quantity_inc" data-sorter="1" data-type="int" data-sort="reactiv_quantity_inc">Створено</th>
                <th class="noselect reactiv_quantity_left" data-sorter="1" data-type="int" data-sort="reactiv_quantity_left">Залишилось</th>
                <th class="noselect consume_count" data-sorter="1" data-type="int" data-sort="consume_count">Використань</th>
                <th class="noselect consume_quantity" data-sorter="1" data-type="int" data-sort="consume_quantity">Фактично використано</th>
            </tr>
            {table02}
        </table>





    </div>
</div>

