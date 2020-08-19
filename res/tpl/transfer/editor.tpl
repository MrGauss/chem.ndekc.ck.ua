<div class="default_editor transfer">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="stock_id" value="0" data-save="1" />
    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />
    <input type="hidden" name="curr_group_id" value="{CURRENT_GROUP_ID}" />

    <div class="elem reagent">
        <label class="label">Що передаємо</label>
        <select data-important="1" class="input select" data-save="1" data-value="0" value="0" name="reagent_id">
            <option value="0">--</option>
            {select:reagent}
        </select>
    </div>

    <div class="elem quantity">
        <label class="label">Кількість</label>
        <input data-important="1" class="input" type="number" min="0" step="0.01" maxlength="10" max="1000000000" name="quantity" value="0" data-save="1" data-mask="999999.9999" data-placeholder="___.___" placeholder="___.___">
    </div>
    <div class="elem units">
        <label class="label">&nbsp;</label>
        <input class="input" type="text" name="units" value="" readonly="readonly">
    </div>

    <div class="elem from_expert_id">
        <label class="label">Особа, що передає реактив чи матеріал</label>
        <select data-important="1" class="input select" data-save="1" data-value="{CURRENT_USER_ID}" value="{CURRENT_USER_ID}" name="from_expert_id" disabled="disabled"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="elem to_stock_id">
        <label class="label">Куди передаємо?</label>
        <select data-important="1" class="input select" data-save="0" value="0" name="to_group_id"><option value="0" selected="selected">--</option>{select:groups}</select>
    </div>

    <div class="elem to_stock_id">
        <label class="label">Назва в лабораторії</label>
        <select data-important="1" class="input select" data-save="1" value="0" name="to_reagent_id"><option value="0" selected="selected">--</option></select>
    </div>

    <div class="elem to_expert_id">
        <label class="label">Хто отримує?</label>
        <select data-important="1" class="input select" data-save="1" data-value="0" value="0" name="to_expert_id"><option value="0" selected="seleted">--</option></select>
    </div>

</div>