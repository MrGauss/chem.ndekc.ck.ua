<!-- ingridient.tpl    -->
<div class="reagent" data-consume_hash="{tag:consume_hash}" data-reagent_id="{tag:reagent_id}" data-reactiv_hash="{tag:reactiv_hash}" data-quantity="{tag:quantity}">
    <table>
        <tr>
            <td class="name"><div class="reagent_name">{tag:reagent_name}</div><span class="inc_date">Видано: {tag:dispersion_inc_date}</span></td>
            <td class="quantity"><div><input data-important="1" class="input" type="text" name="quantity" value="{tag:quantity}" data-save="1" data-mask="999999.99999" data-placeholder="___.___" placeholder="___.___"><span class="reagent_units_short">{tag:reagent_units_short}</span></div></td>
            <td class="button"><span class="add" data-role="button"></span></td>
        </tr>
    </table>
</div>