<tr class="data">
    <th class="numi">{I}</th>
    <th class="name">{tag:recipe:name}</th>
    <td class="data_numeric reactiv_quantity_inc">{tag:reactiv_quantity_inc}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric reactiv_quantity_left">{tag:reactiv_quantity_left}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric consume_quantity">{tag:reactiv_consume_quantity}&nbsp;{tag:units:short_name}</td>
    <td class="dnone">
        <input type="hidden" data-role="sort" name="reagent_name" value="{tag:reagent:name}">
        <input type="hidden" data-role="sort" name="reactiv_quantity_inc" value="{tag:reactiv_quantity_inc}">
        <input type="hidden" data-role="sort" name="reactiv_quantity_left" value="{tag:reactiv_quantity_left}">
        <input type="hidden" data-role="sort" name="reactiv_consume_quantity" value="{tag:reactiv_consume_quantity}">
    </td>
</tr>