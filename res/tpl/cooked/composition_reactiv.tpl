    <div class="reagent" data-role="reactiv"
                data-reactiv_menu_id="{tag:menu:id}"
                data-consume_hash="{tag:consume_hash}"
                data-quantity_left="{tag:reactiv:quantity_left}"
                data-reactiv_hash="{tag:reactiv:hash}"
                data-quantity="{tag:consume_quantity}"
                data-reactiv_units_short="{tag:units:short_name}">
        <table>
            <tr>
                <td class="name">
                    <div class="reagent_name">{tag:menu:name}</div>
                    <span class="inc_date">Видано: <span>{tag:reactiv:inc_date}</span></span>
                    <span class="available">Доступно: <span class="quantity_left">{tag:reactiv:quantity_left}</span>&nbsp;<span class="reagent_units_short">{tag:units:short_name}</span></span>
                </td>
                <td class="quantity"><div><input class="input" name="quantity" type="number" min="0" step="0.01" maxlength="10" max="{tag:reactiv:quantity_left}" value="{tag:consume_quantity}" data-save="1" data-mask="999999.99999" data-placeholder="___.___" placeholder="___.___"><span class="reagent_units_short">{tag:units:short_name}</span></div></td>
                <td class="button"><span class="add" data-role="button"></span></td>
            </tr>
        </table>
    </div>