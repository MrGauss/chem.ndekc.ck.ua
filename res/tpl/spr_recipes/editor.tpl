<div class="default_editor" dara-rand="{RAND}">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="leftside">
        <div class="elem name">
            <label class="label">Назва</label>
            <input class="input" type="text" name="name" value="{tag:name}" data-important="1" data-save="1">
        </div>

        <div class="clear"></div>

        <div class="elem units">
            <label class="label">Одиниця виміру</label>
            <select data-important="1" class="input select" data-save="1" data-value="{tag:units_id}" value="{tag:units_id}" name="units_id"><option value="0">--</option>{select:units}</select>
        </div>

        <div class="clear"></div>
        <div class="elem units">
            <label class="label">Склад</label>
        </div>

        <div class="add_ingredient">
            <select class="input select" data-value="0" value="0" name="reagent_id">
                <option value="0">--</option>
                <optgroup data-role="reactiv" label="Розчини">
                    {select:recipes}
                </optgroup>
                <optgroup data-role="reagent" label="Реактиви">
                    {select:reagent}
                </optgroup>
            </select>
        </div>
        <div class="ingredients">
            <div class="ingredient" data-reagent_id="0"></div>
            {tag:ingredients_html}
        </div>
        <div class="clear"></div>
    </div>

    <div class="rightside">
        <div class="elem comment">
            <label class="label">Коментар</label>
            <textarea class="input textarea" type="text" name="comment" data-save="1">{tag:comment}</textarea>
            <div class="clear"></div>
        </div>
        <div class="clear"></div>
    </div>

    <div class="clear"></div>
</div>