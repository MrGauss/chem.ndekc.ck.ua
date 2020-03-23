<!--

array (
    'hash' => '',
    'reactiv_menu_id' => '0',
    'quantity_inc' => '0',
    'quantity_left' => '0',
    'inc_expert_id' => '0',
    'region_id' => '0',
    'group_id' => '0',
    'reactiv_name' => '--',
    'reactiv_units_id' => '0',
    'reactiv_comment' => '',
    'composition' =>
    array (
    ),
    'key' => '5ccff84d331477713ee743733af314323dbea1a2',
)

-->

<div class="default_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="hash" value="{tag:hash}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem recipe">
        <label class="label">Рецепт приготування робочого реактиву</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:reactiv_menu_id}" value="{tag:reactiv_menu_id}" name="reactiv_menu_id"><option value="0">--</option>{select:recipes}</select>
    </div>

    <div class="clear"></div>

    <div class="elem ingridients recipe_needed">
        <label class="label">Доступні інгрідієнти</label>
        <div id="ingridients" class="list">
            {ingridients}
        </div>
    </div>

    <div class="elem composition recipe_needed">
        <label class="label">Склад</label>
        <div id="composition" class="list">
            {composition}
        </div>
    </div>

    <div class="clear"></div>

    <div class="elem quantity recipe_needed">
        <label class="label">Кількість приготованого реактиву</label>
        <input data-important="1" class="input" type="text" name="quantity_inc" value="{tag:quantity_inc}" data-save="1" data-mask="9999.9999" data-placeholder="___.___" placeholder="___.___">
    </div>
    <div class="elem units recipe_needed">
        <label class="label">Одиниця виміру</label>
        <select data-important="1" class="input select" data-value="0" value="0" name="units_id" disabled="disabled"><option value="0">--</option>{select:units}</select>
    </div>

    <div class="clear"></div>

    <div class="elem inc_date recipe_needed">
        <label class="label">Дата приготування</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="inc_date" value="{tag:inc_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="elem dead_date recipe_needed">
        <label class="label">Кінцева дата зберігання</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="dead_date" value="{tag:dead_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
    </div>

    <div class="elem inc_expert_id recipe_needed">
        <label class="label">Особа, яка приготувала реактив</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:inc_expert_id}" value="{tag:inc_expert_id}" name="inc_expert_id"><option value="0">--</option>{select:user}</select>
    </div>

    <div class="clear"></div>


    <div class="elem safe_place recipe_needed">
        <label class="label">Місце зберігання</label>
        <input data-important="1" class="input" type="text" name="safe_place" value="{tag:safe_place}" data-save="1" data-autocomplete="1" data-key="{autocomplete:safe_place:key}" data-table="{autocomplete:table}" data-column="safe_place">
    </div>

    <div class="elem safe_needs recipe_needed">
        <label class="label">Умови зберігання</label>
        <input data-important="1" class="input" type="text" name="safe_needs" value="{tag:safe_needs}" data-save="1" data-autocomplete="1" data-key="{autocomplete:safe_needs:key}" data-table="{autocomplete:table}" data-column="safe_needs">
    </div>

    <div class="clear"></div>

    <div class="elem comment recipe_needed">
        <label class="label">Примітки</label>
        <input class="input" type="text" name="comment" value="{tag:comment}" data-save="1">
    </div>

    <div class="clear"></div>
</div>