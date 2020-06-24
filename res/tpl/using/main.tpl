<div id="list_frame" class="using">

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
                <td class="date"            data-sorter="1" data-type="int" data-sort="date">Дата</td>
                <td class="purpose_name"    data-sorter="1" data-type="int" data-sort="purpose_id">Мета використання</td>
                <td class="name"            data-sorter="1" data-type="txt" data-sort="result">Результат використання</td>
                <td class="consume">Що використано</td>
                <td></td>
            </tr>
        </table>
    </div>

    <div id="list" class="list">

        {list}

    </div>
</div>

