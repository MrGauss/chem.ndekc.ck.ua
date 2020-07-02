<div class="default_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="hash" value="{tag:hash}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem purpose">
        <label class="label">Мета використання</label>
        <select tabindex="2" data-important="1" class="input select" data-save="1" data-value="{tag:purpose_id}" value="{tag:purpose_id}" name="purpose_id"><option value="0">--</option>{select:purpose}</select>
    </div>

    <div class="elem reactiv_menu_id" data-purpose="reactiv">
        <label class="label">Рецепт приготування</label>
        <select tabindex="3" disabled="disabled" class="input select" disabled="disabled" data-value="{tag:reactiv:reactiv_menu_id}" value="{tag:reactiv:reactiv_menu_id}" name="reactiv_menu_id"><option value="0">--</option>{select:recipes}</select>
    </div>

    <div class="elem quantity_inc" data-purpose="reactiv">
        <label class="label">Кількість</label>
        <input tabindex="4" class="input" type="text" name="quantity_inc" value="{tag:reactiv:quantity_inc}" disabled="disabled">
    </div>

    <div class="elem units_short_name" data-purpose="reactiv">
        <label class="label">&nbsp;</label>
        <input class="input noimportant" type="text" name="obj_count" value="{tag:reactiv:units:short_name}" disabled="disabled">
    </div>

    <div class="elem exp_number" data-purpose="expertise">
        <label class="label">Номер висновку</label>
        <input tabindex="5" data-important="1" class="input" type="text" name="exp_number" value="{tag:exp_number}" data-save="1">
    </div>

    <!-- div class="elem exp_date" data-purpose="expertise">
        <label class="label">Дата</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="exp_date" value="{tag:exp_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div -->

    <div class="elem obj_count" data-purpose="expertise">
        <label class="label">Об'єктів</label>
        <input tabindex="6" data-important="1" class="input" type="number" min="0" step="1" maxlength="5" max="1000000000" name="obj_count" value="{tag:obj_count}" data-save="1" data-mask="99999" data-placeholder="" placeholder="">
    </div>

    <div class="elem tech_info" data-purpose="maintenance other science utilisation">
        <label class="label">Деталі використання</label>
        <input tabindex="7" class="input" type="text" name="tech_info" value="{tag:tech_info}" data-save="1">
    </div>

    <div class="clear"></div>

    <div class="elem ucomment">
        <label class="label">Коментар</label>
        <input tabindex="9" class="input" type="text" name="comment" value="{tag:ucomment}" data-save="1">
    </div>

    <div class="elem user_id">
        <label class="label">Використав</label>
        <select disabled="disabled" class="input select" data-value="{CURRENT_USER_ID}" value="{CURRENT_USER_ID}" name="user_id" data-save="1" data-important="1"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="elem date">
        <label class="label">Дата використання</label>
        <input tabindex="8" data-important="1" class="input" type="text" autocomplete="off" name="date" value="{tag:date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="clear"></div>

    <div class="sides">
        <div class="side side1">
            <div class="elem list">
                <label class="label">Реактиви чи розхідні матеріали</label>
                <div id="consume_list" class="listline">{consume:list}</div>
                <div id="dispersion_list" class="selectable_list" data-empty="empty_dispersion">{dispersion:list}</div>
            </div>
        </div>
        <div class="side side2">
            <div class="elem list">
                <label class="label">Робочі реактиви (розчини)</label>
                <div id="reactiv_consume_list" class="listline">{reactiv_consume:list}</div>
                <div id="cooked_list" class="selectable_list" data-empty="empty_reactiv">{cooked:list}</div>
            </div>
        </div>
        <div class="clear"></div>
    </div>

    <div class="elem search">
        <input class="input" type="text" name="search" value="" data-save="1" placeholder="Введіть пошукову фразу..." data-placeholder="Введіть фразу для пошуку..." tabindex="1">
    </div>

    <div id="empty_dispersion" class="dnone">
        {@include=using/consume_line}
    </div>

    <div id="empty_reactiv" class="dnone">
        {@include=using/reactiv_consume_line}
    </div>

    <div class="clear"></div>
</div>