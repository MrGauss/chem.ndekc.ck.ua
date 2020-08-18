<div class="default_editor transfer">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="hash" value="{tag:hash}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem reagent">
        <label class="label">Що передаємо</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:reagent_id}" value="{tag:reagent_id}" name="reagent_id">
            <option value="0">--</option>
            {select:reagent}
        </select>
    </div>

    <div class="elem quantity">
        <label class="label">Кількість</label>
        <input data-important="1" class="input" type="number" min="0" step="0.01" maxlength="10" max="1000000000" name="quantity_inc" value="{tag:quantity_inc}" data-save="1" data-mask="999999.9999" data-placeholder="___.___" placeholder="___.___">
    </div>
    <div class="elem units">
        <label class="label">&nbsp;</label>
        <input class="input" type="text" name="units" value="{tag:reagent_units}" readonly="readonly">
    </div>

    <div class="elem from_expert_id">
        <label class="label">Особа, що передає реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:out_expert_id}" value="{tag:out_expert_id}" name="out_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="elem to_stock_id">
        <label class="label">Куди передається реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:out_expert_id}" value="{tag:out_expert_id}" name="out_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="elem to_expert_id">
        <label class="label">Особа, що отримала реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:out_expert_id}" value="{tag:out_expert_id}" name="out_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

</div>