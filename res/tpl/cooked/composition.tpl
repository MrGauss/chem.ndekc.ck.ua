<!-- composition.tpl    -->
<div class="reagent" data-dispersion_id="{tag:dispersion_id}" data-consume_hash="{tag:consume_hash}" data-reagent_name="{tag:reagent_name}" data-quantity_left="{tag:quantity_left}" data-reagent_id="{tag:reagent_id}" data-reactiv_hash="{tag:reactiv_hash}" data-quantity="{tag:quantity}" data-reagent_units_short="{tag:reagent_units_short}">
    <table>
        <tr>
            <td class="name">
                <div class="reagent_name">{tag:reagent_name} [{tag:reagent_number}]</div>
                <span class="inc_date">Видано: <span>{tag:dispersion_inc_date}</span></span>
                <span class="available">Доступно: <span class="quantity_left">{tag:quantity_left}</span>&nbsp;<span class="reagent_units_short">{tag:reagent_units_short}</span></span>
            </td>
            <td class="quantity"><div><input data-important="1" class="input"  name="quantity" type="number" min="0" step="0.01" maxlength="10" max="{tag:quantity_left}" value="{tag:quantity}" data-save="1" data-mask="999999.99999" data-placeholder="___.___" placeholder="___.___"><span class="reagent_units_short">{tag:reagent_units_short}</span></div></td>
            <td class="button"><span class="add" data-role="button"></span></td>
        </tr>
    </table>
</div>