<!-- composition.tpl    -->
<div class="reagent" data-dispersion_id="{tag:dispersion_id}" data-consume_hash="{tag:consume_hash}" data-reagent_name="{tag:reagent:name}" data-quantity_left="{tag:dispersion_quantity_left}" data-reagent_id="{tag:reagent_id}" data-reactiv_hash="{tag:reactiv_hash}" data-quantity="{tag:quantity}" data-reagent_units_short="{tag:reagent:units:short_name}">
    <table>
        <tr>
            <td class="name">
                <div class="reagent_name">{tag:reagent:name} [{tag:reagent_number}]</div>
                <span class="inc_date">Видано: <span>{tag:dispersion_inc_date}</span></span>
                <span class="available">Доступно: <span class="quantity_left">{tag:dispersion_quantity_left}</span>&nbsp;<span class="reagent_units_short">{tag:reagent:units:short_name}</span></span>
            </td>
            <td class="quantity"><div><input data-important="1" class="input"  name="quantity" type="number" min="0" step="0.01" maxlength="10" max="{tag:dispersion_quantity_left}" value="{tag:quantity}" data-save="1" data-mask="999999.99999" data-placeholder="___.___" placeholder="___.___"><span class="reagent_units_short">{tag:reagent:units:short_name}</span></div></td>
            <td class="button"><span class="add" data-role="button"></span></td>
        </tr>
    </table>
</div>

<!--

{tag:reactiv_hash}
{tag:consume_hash}
{tag:using_hash}
{tag:quantity}
{tag:dispersion_id}
{tag:consume_ts}
{tag:consume_date}
{tag:using_date}
{tag:purpose_id}
{tag:dispersion_inc_date}
{tag:reagent_id}
{tag:reagent_number}
{tag:numi}
{tag:reagent:id}
{tag:reagent:ts}
{tag:reagent:name}
{tag:reagent:created_by_expert_id}
{tag:reagent:units_id}
{tag:reagent:units_name}
{tag:reagent:units:id}
{tag:reagent:units:name}
{tag:reagent:units:position}
{tag:reagent:units:short_name}

-->