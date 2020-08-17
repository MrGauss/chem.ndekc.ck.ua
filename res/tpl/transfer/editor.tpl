<div class="default_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="hash" value="{tag:hash}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem">
        <label class="label">Назва реактиву чи витратного матеріалу</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:reagent_id}" value="{tag:reagent_id}" name="reagent_id">
            <option value="0">--</option>
            {select:reagent}
        </select>
    </div>

    <div class="elem">
        <label class="label">Кількість</label>
        <input data-important="1" class="input" type="number" min="0" step="0.01" maxlength="10" max="1000000000" name="quantity_inc" value="{tag:quantity_inc}" data-save="1" data-mask="999999.9999" data-placeholder="___.___" placeholder="___.___">
    </div>
    <div class="elem">
        <label class="label">&nbsp;</label>
        <input class="input" type="text" name="units" value="{tag:reagent_units}" readonly="readonly">
    </div>

    <div class="elem out_expert_id">
        <label class="label">Особа, яка передала реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:out_expert_id}" value="{tag:out_expert_id}" name="out_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="elem out_expert_id">
        <label class="label">Особа, яка отримала реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:out_expert_id}" value="{tag:out_expert_id}" name="out_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

</div>