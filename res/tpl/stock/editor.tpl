<div class="default_editor stock_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem reagent">
        <label class="label">Назва реактиву чи витратного матеріалу</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:reagent_id}" value="{tag:reagent_id}" name="reagent_id"><option value="0">--</option>{select:reagent}</select>
    </div>

    <div class="elem quantity">
        <label class="label">Кількість</label>
        <input data-important="1" class="input" type="number" min="0" step="0.01" maxlength="10" max="1000000000" name="quantity_inc" value="{tag:quantity_inc}" data-save="1" data-mask="999999.9999" data-placeholder="___.___" placeholder="___.___">
    </div>
    <div class="elem units">
        <label class="label">&nbsp;</label>
        <input class="input" type="text" name="units" value="{tag:reagent_units}" readonly="readonly">
    </div>

    <div class="elem inc_date">
        <label class="label">Дата надходження</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="inc_date" value="{tag:inc_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
    </div>

    <div class="elem create_date">
        <label class="label">Дата виробництва</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="create_date" value="{tag:create_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10">
    </div>

    <div class="elem dead_date">
        <label class="label">Кінцева дата</label>
        <input data-important="1" class="input" type="text" autocomplete="off" name="dead_date" value="{tag:dead_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="+1d" data-maxdate="+10y">
    </div>

    <div class="clear"></div>

    <div class="elem reagent_state">
        <label class="label">Форма надходження</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:reagent_state_id}" value="{tag:reagent_state_id}" name="reagent_state_id"><option value="0">--</option>{select:reagent_state}</select>
    </div>

    <div class="elem clearence">
        <label class="label">Ступінь очистки</label>
        <select class="input select" data-save="1" data-value="{tag:clearence_id}" value="{tag:clearence_id}" name="clearence_id"><option value="0">--</option>{select:clearence}</select>
    </div>

    <div class="elem certif">
        <label class="label">Сертифікат якості</label>
        <select class="input select" data-save="1" data-value="{tag:is_sertificat}" value="{tag:is_sertificat}" name="is_sertificat"><option value="1">Так</option><option value="0">Ні</option></select>
    </div>

    <div class="elem is_suitability">
        <label class="label">Висновок про придатність</label>
        <select class="input select" data-save="1" data-value="{tag:is_suitability}" value="{tag:is_suitability}" name="is_suitability"><option value="1">Так</option><option value="0">Ні</option></select>
    </div>


    <div class="clear"></div>

    <div class="elem creator">
        <label class="label">Виробник</label>
        <input data-important="1" class="input" type="text" name="creator" value="{tag:creator}" data-save="1" data-autocomplete="1" data-key="{autocomplete:creator:key}" data-table="{autocomplete:table}" data-column="creator">
    </div>

    <div class="clear"></div>

    <div class="elem danger_class">
        <label class="label">Клас небезпеки</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:danger_class_id}" value="{tag:danger_class_id}" name="danger_class_id"><option value="0">--</option>{select:danger_class}</select>
    </div>

    <div class="elem safe_needs">
        <label class="label">Умови зберігання</label>
        <input data-important="1" class="input" type="text" name="safe_needs" value="{tag:safe_needs}" data-save="1" data-autocomplete="1" data-key="{autocomplete:safe_needs:key}" data-table="{autocomplete:table}" data-column="safe_needs">
    </div>

    <div class="elem safe_place">
        <label class="label">Місце зберігання</label>
        <input data-important="1" class="input" type="text" name="safe_place" value="{tag:safe_place}" data-save="1" data-autocomplete="1" data-key="{autocomplete:safe_place:key}" data-table="{autocomplete:table}" data-column="safe_place">
    </div>

    <div class="clear"></div>

    <div class="elem comment">
        <label class="label">Примітки</label>
        <input class="input" type="text" name="comment" value="{tag:comment}" data-save="1">
    </div>

    <div class="clear"></div>

    <div class="elem expert">
        <label class="label">Особа, яка здійснила перевірку та взяла на облік</label>
        <input class="input" type="text" name="expert" value="{tag:expert_surname} {tag:expert_name} {tag:expert_phname}" readonly="readonly">
    </div>

    <div class="clear"></div>
</div>