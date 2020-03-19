<div class="default_editor stock_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem reagent">
        <label class="label">Назва реактиву чи витратного матеріалу</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:stock_id}" value="{tag:stock_id}" name="stock_id"><option value="0">--</option>{select:stock}</select>
    </div>

    <div class="elem inc_date">
        <label class="label">Дата видачі</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="inc_date" value="{tag:inc_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
    </div>

    <div class="elem quantity">
        <label class="label">Кількість</label>
        <input data-important="1" class="input" type="text" name="quantity_inc" value="{tag:quantity_inc}" data-save="1" data-mask="999999.99999" data-placeholder="___.___" placeholder="___.___">
    </div>
    <div class="elem units">
        <label class="label">&nbsp;</label>
        <input class="input" type="text" name="units" value="{tag:reagent_units_short}">
    </div>

    <div class="clear"></div>

    <div class="elem quantity_left">
        <label class="label">Не використаний залишок</label>
        <input class="input" type="text" name="quantity_left" value="{tag:quantity_left}" readonly="readonly">
    </div>

    <div class="elem quantity_left">
        <label class="label">Доступно на складі</label>
        <input class="input" type="text" name="reagent_quantity_left" value="" readonly="readonly">
    </div>

    <div class="clear"></div>

    <div class="elem inc_expert_id">
        <label class="label">Особа, яка здійснила видачу</label>
        <input class="input" type="text" name="creator" value="{tag:inc_expert_surname} {tag:inc_expert_name} {tag:inc_expert_phname}">
    </div>

    <div class="elem out_expert_id">
        <label class="label">Особа, яка отримала реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:out_expert_id}" value="{tag:out_expert_id}" name="out_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="clear"></div>

    <div class="elem comment">
        <label class="label">Примітки</label>
        <input class="input" type="text" name="comment" value="{tag:comment}" data-save="1">
    </div>

    <div class="clear"></div>
</div>