<div id="list_frame" class="dispersion">
    <div id="filters" class="filters">
        <button id="create" type="button" data-id="0">Створити</button>
        <button id="search" type="button">Шукати</button>
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

