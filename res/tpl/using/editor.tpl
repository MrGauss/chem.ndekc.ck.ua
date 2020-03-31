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

    <div class="elem reactiv_menu_id" data-purpose="reactiv">
        <label class="label">Рецепт приготування</label>
        <select disabled="disabled" class="input select" data-value="{tag:reactiv_menu_id}" value="{tag:reactiv_menu_id}" name="reactiv_menu_id"><option value="0">--</option>{select:recipes}</select>
    </div>

    <div class="elem quantity_inc" data-purpose="reactiv">
        <label class="label">Кількість</label>
        <input class="input" type="text"  name="obj_count" value="{tag:reactiv:quantity_inc}"  disabled="disabled">
    </div>

    <div class="elem units_short_name" data-purpose="reactiv">
        <label class="label">&nbsp;</label>
        <input class="input noimportant" type="text" name="obj_count" value="{tag:reactiv:units:short_name}"  disabled="disabled">
    </div>



    <div class="elem exp_number" data-purpose="expertise">
        <label class="label">Номер висновку</label>
        <input data-important="1" class="input" type="text" name="exp_number" value="{tag:exp_number}" data-save="1">
    </div>

    <div class="elem exp_date" data-purpose="expertise">
        <label class="label">Дата</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="exp_date" value="{tag:exp_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="elem obj_count" data-purpose="expertise">
        <label class="label">Об'єктів</label>
        <input data-important="1" class="input" type="number" min="0" step="1" maxlength="5" max="1000000000" name="obj_count" value="{tag:obj_count}" data-save="1" data-mask="99999" data-placeholder="" placeholder="">
    </div>



    <div class="elem tech_info" data-purpose="maintenance">
        <label class="label">Деталі використання</label>
        <input class="input" type="text" name="tech_info" value="{tag:tech_info}" data-save="1">
    </div>

    <div class="clear"></div>

    <div class="elem date">
        <label class="label">Дата використання</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="date" value="{tag:date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="elem user_id">
        <label class="label">Використав</label>
        <select disabled="disabled" class="input select" data-value="{CURRENT_USER_ID}" value="{CURRENT_USER_ID}" name="user_id"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="elem ucomment">
        <label class="label">Коментар</label>
        <input class="input" type="text" name="comment" value="{tag:ucomment}" data-save="1">
    </div>



    <div class="clear"></div>

    <div class="sides">
        <div class="side side1">
            <div class="elem list">
                <label class="label">Реактиви</label>
                <div class="listline">



<div class="consume"
        data-dispersion_id="{tag:dispersion_id}"
        data-consume_hash="{tag:consume_hash}"
        data-reagent_name="{tag:reagent:name}"
        data-quantity_left="{tag:dispersion_quantity_left}"
        data-reagent_id="{tag:reagent_id}"
        data-reactiv_hash="{tag:reactiv_hash}"
        data-quantity="{tag:quantity}"
        data-reagent_units_short="{tag:reagent:units:short_name}"
>
    <table>
        <tr>
            <td class="name">
                <div class="reagent_name_fr">
                    <div class="reagent_name">{tag:reagent:name} [{tag:reagent_number}]</div>
                    <span class="inc_date">Видано: <span>{tag:dispersion_inc_date}</span></span>
                    <span class="available">Доступно: <span class="quantity_left">{tag:dispersion_quantity_left}</span>&nbsp;<span class="reagent_units_short">{tag:reagent:units:short_name}</span></span>
                </div>
            </td>
            <td class="quantity"><div><input class="input"  name="quantity" type="number" min="0" step="0.01" maxlength="10" max="{tag:dispersion_quantity_left}" value="{tag:quantity}" data-save="1" data-mask="999999.99999" data-placeholder="___.___" placeholder="___.___"><span class="reagent_units_short">{tag:reagent:units:short_name}</span></div></td>
            <td class="button"><span class="add" data-role="button"></span></td>
        </tr>
    </table>
</div>



                </div>
            </div>

        </div>
        <div class="side side2">
            <div class="elem list">
                <label class="label">Приготовані реактиви</label>
                <div class="listline">






                </div>
            </div>
        </div>
        <div class="clear"></div>
    </div>

    <div class="clear"></div>
</div>