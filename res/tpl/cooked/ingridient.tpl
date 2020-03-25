<!-- ingridient.tpl    -->
<div class="reagent" data-dispersion_id="{tag:id}" data-inc_date="{tag:inc_date}" data-quantity_left="{tag:quantity_left}" data-reagent_id="{tag:reagent_id}" data-reagent_name="{tag:reagent:name} [{tag:reagent_number}]" data-quantity_left="{tag:quantity_left}" data-reagent_units_short="{tag:reagent:units:short_name}">
    <table>
        <tr>
            <td class="name"><div class="reagent_name">{tag:reagent:name} [{tag:reagent_number}]</div><span class="inc_date">Видано: {tag:inc_date}</span></td>
            <td class="quantity_left">{tag:quantity_left}&nbsp;{tag:reagent:units:short_name}</td>
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