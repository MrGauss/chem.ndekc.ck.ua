<div id="list_frame" class="stock">
    <div id="filters" class="filters">
        <button id="create" type="button" data-id="0">��������</button>

        <div class="element">
            <label class="label">�������</label>
            <select class="input select" data-value="0" value="0" name="reagent_id" data-filter="1"><option value="0">--</option>{select:reagent}</select>
        </div>

        <button id="search" type="button">������</button>
    </div>

    <div id="list" class="list">
        <div class="line header">
            <table>
                <tr>
                    <td class="numi">&nbsp;</td>
                    <td class="reagent">�����</td>
                    <td class="number">�����</td>
                    <td class="inc_date">���� �����������</td>
                    <td class="quantity_inc">�������</td>
                    <td class="quantity_left">�� �����</td>
                    <td class="quantity_dispersed">������</td>
                    <td class="quantity_not_used">�����������</td>
                    <td></td>
                </tr>
            </table>
        </div>


        {list}
    </div>
</div>

