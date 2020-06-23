<div class="default_editor">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="hash"        value="{tag:hash}"       data-save="1" />
    <input type="hidden" name="key"         value="{tag:key}"        data-save="1" />

    <div id="empty_composition_reagent" class="dnone">{@include=cooked/composition_reagent}</div>
    <div id="empty_composition_reactiv" class="dnone">{@include=cooked/composition_reactiv}</div>

    <div class="elem recipe">
        <label class="label">Рецепт приготування робочого реактиву</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:reactiv_menu_id}" value="{tag:reactiv_menu_id}" name="reactiv_menu_id"><option value="0">--</option>{select:recipes}</select>
    </div>

    <div class="clear"></div>

    <table class="panel recipe_needed">
        <tr>
            <td class="side1 naming"><div class="elem"><label class="label">Склад</label></div><div class="clear"></div></td>
            <td class="side2" rowspan="4">

                <div class="elems_line">
                    <div class="elem quantity">
                        <label class="label">Кількість реактиву</label>
                        <input data-important="1" class="input" type="number" min="0" step="0.01" maxlength="10" max="1000000000" name="quantity_inc" value="{tag:quantity_inc}" data-save="1" data-mask="9999.9999" data-placeholder="___.___" placeholder="___.___">
                    </div>
                    <div class="elem units">
                        <label class="label">Одиниці виміру</label>
                        <select data-important="1" class="input select" data-value="0" value="0" name="units_id" disabled="disabled"><option value="0">--</option>{select:units}</select>
                    </div>
                    <div class="clear"></div>
                </div>

                <div class="elems_line">
                    <div class="elem inc_date">
                        <label class="label">Дата приготування</label>
                        <input data-important="1" class="input" type="text" autocomplete="off" name="inc_date" value="{tag:inc_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
                    </div>
                    <div class="elem dead_date">
                        <label class="label">Кінцева дата</label>
                        <input data-important="1" class="input" type="text" autocomplete="off" name="dead_date" value="{tag:dead_date}" data-save="1" data-mask="99.99.9999" data-placeholder="__.__.____" placeholder="__.__.____" maxlength="10" data-mindate="-1y" data-maxdate="+1y">
                    </div>
                    <div class="clear"></div>
                </div>

                <div class="elems_line">
                    <div class="elem inc_expert_id">
                        <label class="label">Особа, яка приготувала реактив</label>
                        <select data-important="1" class="input select" data-save="1" data-value="{tag:inc_expert_id}" value="{tag:inc_expert_id}" name="inc_expert_id"><option value="0">--</option>{select:user}</select>
                    </div>
                    <div class="clear"></div>
                </div>

                <div class="elems_line">
                    <div class="elem safe_place">
                        <label class="label">Місце зберігання</label>
                        <input data-important="0" class="input" type="text" name="safe_place" value="{tag:safe_place}" data-save="1" data-autocomplete="1" data-key="{autocomplete:safe_place:key}" data-table="{autocomplete:table}" data-column="safe_place">
                    </div>
                </div>

                <div class="elems_line">
                    <div class="elem safe_needs">
                        <label class="label">Умови зберігання</label>
                        <input data-important="0" class="input" type="text" name="safe_needs" value="{tag:safe_needs}" data-save="1" data-autocomplete="1" data-key="{autocomplete:safe_needs:key}" data-table="{autocomplete:table}" data-column="safe_needs">
                    </div>
                    <div class="clear"></div>
                </div>

                <div class="elems_line">
                    <div class="elem comment recipe_needed">
                        <label class="label">Примітки</label>
                        <textarea class="input textarea" name="comment" data-save="1">{tag:comment}</textarea>
                    </div>
                    <div class="clear"></div>
                </div>

                <div class="clear"></div>

            </td>
        </tr>
        <tr><td><div id="composition" class="list elem">{composition}<div class="clear"></div></div><div class="clear"></div></td></tr>
        <tr><td class="side1 naming"><div class="elem"><label class="label">Інгрідієнти</label></div><div class="clear"></div></td></tr>
        <tr><td><div id="ingridients" class="list elem">{ingridients}<div class="clear"></div> </div></td></tr>
    </table>



    <div class="clear"></div>

</div>