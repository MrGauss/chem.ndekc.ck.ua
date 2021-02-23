<div class="default_editor stock_editor" dara-rand="{RAND}">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem name">
        <label class="label">Назва реактиву чи витратного матеріалу</label>
        <input class="input" type="text" name="name" value="{tag:name}" data-important="1" data-save="1">
    </div>

    <div class="clear"></div>

    <div class="elem units">
        <label class="label">Одиниця виміру</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:units_id}" value="{tag:units_id}" name="units_id"><option value="0">--</option>{select:units}</select>
    </div>

    <div class="elem is_precursor">
        <input id="is_precursor" class="input" type="checkbox" name="is_precursor" value="1" data-value="{tag:is_precursor}" data-save="1">
        <label for="is_precursor" class="label">являється прекурсором</label>
    </div>

    <div class="clear"></div>

    <div class="edit_info">
        Будьте уважними!<br>Даний довідник є глобальним, його редагування спричинить внесення змін в програмний засіб загалом!
    </div>

    <div class="clear"></div>
</div>