<div class="default_editor prolongation" dara-rand="{RAND}">

    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <div class="elem reagent_name">
        <label class="label">Назва реактиву чи витратного матеріалу</label>
        <input class="input" type="text" name="name" value="[{stock:reagent_number}] {reagent:name}" data-save="0" disabled="disabled">
    </div>

    <div class="clear"></div>

    <div class="elem" id="prolongation_history">
        <div class="list">
            <div class="show_add_panel">Додати</div>
            {prolongation:list}
        </div>
        <div id="empty" class="dnone">{@include=prolongation/editor_line}</div>
    </div>
    <div class="clear"></div>

    <div class="add_new dnone">

        <div class="elem date_before_prolong">
            <label class="label">Термін придатності до перевірки</label>
            <input class="input" type="text" name="date_before_prolong" value="" autocomplete="off" data-important="1" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-10y" data-maxdate="+20y">
        </div>

        <div class="elem date_after_prolong">
            <label class="label">Термін придатності після перевірки</label>
            <input class="input" type="text" name="date_after_prolong" value="" autocomplete="off" data-important="1" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-10y" data-maxdate="+20y">
        </div>

        <div class="elem expert_id">
            <label class="label">Перевірку здійснив</label>
            <select data-important="0" class="input select" disabled="disabled" data-save="0" data-value="{CURRENT_USER_ID}" value="{CURRENT_USER_ID}" name="expert_id"><option value="0">--</option>{select:user}</select>
        </div>

        <div class="elem act_date">
            <label class="label">Дата складання акту</label>
            <input class="input" type="text" name="act_date" value="" autocomplete="off" data-important="1" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-10y" data-maxdate="+20y">
        </div>

        <div class="elem act_number">
            <label class="label">Номер акту</label>
            <input class="input" type="text" name="act_number" value="" autocomplete="off" data-important="0" data-save="1">
        </div>

        <div class="elem prolong_button">
            <button id="add_prolong" class="add_prolong">Зберегти</button>
        </div>

    </div>



    <div class="clear"></div>
</div>