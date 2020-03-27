<div class="default_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem purpose">
        <label class="label">Мета використання</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:purpose_id}" value="{tag:purpose_id}" name="purpose_id"><option value="0">--</option>{select:purpose}</select>
    </div>

    <div class="elem reactiv_menu_id">
        <label class="label">Рецепт приготування</label>
        <select disabled="disabled" class="input select" data-value="{tag:reactiv_menu_id}" value="{tag:reactiv_menu_id}" name="reactiv_menu_id"><option value="0">--</option>{select:recipes}</select>
    </div>


    <div class="elem quantity_inc">
        <label class="label">Кількість</label>
        <input class="input" type="text"  name="obj_count" value="{tag:reactiv:quantity_inc}"  disabled="disabled">
    </div>

    <div class="elem units_short_name">
        <label class="label">&nbsp;</label>
        <input class="input" type="text" name="obj_count" value="{tag:reactiv:units:short_name}"  disabled="disabled">
    </div>







    <div class="elem exp_number">
        <label class="label">Номер висновку</label>
        <input data-important="1" class="input" type="text" min="0" step="1" maxlength="10" max="1000000000" name="exp_number" value="{tag:exp_number}" data-save="1">
    </div>

    <div class="elem exp_date">
        <label class="label">Дата</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="exp_date" value="{tag:exp_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="elem obj_count">
        <label class="label">Об'єктів</label>
        <input data-important="1" class="input" type="number" min="0" step="1" maxlength="5" max="1000000000" name="obj_count" value="{tag:obj_count}" data-save="1" data-mask="99999" data-placeholder="" placeholder="">
    </div>



    <div class="clear"></div>

    <div class="elem date">
        <label class="label">Дата використання</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="date" value="{tag:date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="clear"></div>

    <div class="sides">
        <div class="side side1">
            <div class="elem list">
                <label class="label">Реактиви</label>
                <div class="listline">123</div>
            </div>

        </div>
        <div class="side side2">
            <div class="elem list">
                <label class="label">Приготовані реактиви</label>
                <div class="listline">123</div>
            </div>
        </div>
        <div class="clear"></div>
    </div>

    <div class="clear"></div>
</div>