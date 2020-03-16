<div class="default_editor" dara-rand="{RAND}">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem name">
        <label class="label">Назва</label>
        <input class="input" type="text" name="name" value="{tag:name}" data-important="1" data-save="1">
    </div>


    <div class="clear"></div>

    <div class="add_ingredient">
        <select class="input select" data-value="0" value="0" name="reagent_id"><option value="0">--</option>{select:reagent}</select>
    </div>
    <div class="ingredients">
        <div class="ingredient" data-reagent_id="0"></div>
        {tag:ingredients_html}
    </div>

    <div class="clear"></div>


    <div class="clear"></div>
</div>