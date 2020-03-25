<div id="list_frame" class="stock">
    <div id="filters" class="filters">
        <button id="create" type="button" data-id="0">Створити</button>

        <div class="element">
            <label class="label">Реактив</label>
            <select class="input select" data-value="0" value="0" name="reagent_id" data-filter="1"><option value="0">--</option>{select:reagent}</select>
        </div>

        <button id="search" type="button">Шукати</button>
    </div>

    <div id="list" class="list">
        <div class="line header">
            <table>
                <tr>
                    <td class="numi">&nbsp;</td>
                    <td class="reagent">Назва</td>
                    <td class="number">Номер</td>
                    <td class="inc_date">Дата надходження</td>
                    <td class="quantity_inc">Надійшло</td>
                    <td class="quantity_left">На складі</td>
                    <td class="quantity_dispersed">Видано</td>
                    <td class="quantity_not_used">Використано</td>
                    <td></td>
                </tr>
            </table>
        </div>


        {list}
    </div>
</div>

