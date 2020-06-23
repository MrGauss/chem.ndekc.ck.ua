<div id="list_frame" class="spr_reactives">

    <div id="filters" class="filters">
        <table class="filters_header_frame">
            <tr>
                <td class="create_button"><button id="create" type="button" data-hash="">Створити</button></td>
                <td class="filters_area">
                    <div class="filters_list">

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
                <td class="name"          data-sorter="1" data-type="txt" data-sort="reagent">Назва</td>
                <td class="inc_date"      data-sorter="1" data-type="int" data-sort="inc_date">Дата приготування</td>
                <td class="dead_date"     data-sorter="1" data-type="int" data-sort="dead_date">Кінцева дата</td>
                <td class="quantity_inc"  data-sorter="1" data-type="int" data-sort="quantity_inc">Приготована кількість</td>
                <td class="quantity_left" data-sorter="1" data-type="int" data-sort="quantity_left">Залишилось</td>
                <td class="composition">Склад</td>
            </tr>
        </table>
    </div>

    <div id="list" class="list">
        {list}
    </div>
</div>

