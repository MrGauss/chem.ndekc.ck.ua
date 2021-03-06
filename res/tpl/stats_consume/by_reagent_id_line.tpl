<tr class="data">
    <th class="numi">{I}</th>
    <th class="name">{tag:reagent:name}</th>
    <td class="data_numeric stock_quantity_inc">{tag:stock_quantity_inc}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric stock_quantity_left">{tag:stock_quantity_left}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric dispersion_quantity_inc">{tag:dispersion_quantity_inc}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric dispersion_quantity_left">{tag:dispersion_quantity_left}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric consume_quantity">{tag:consume_quantity_full}&nbsp;{tag:units:short_name}</td>
    <td class="data_numeric consume_quantity">{tag:consume_quantity}&nbsp;{tag:units:short_name}</td>

    <td class="data_numeric consume_count">{tag:consume_count}</td>
    <td class="dnone">
        <input type="hidden" data-role="sort" name="reagent_name" value="{tag:reagent:name}">
        <input type="hidden" data-role="sort" name="stock_quantity_inc" value="{tag:stock_quantity_inc}">
        <input type="hidden" data-role="sort" name="stock_quantity_left" value="{tag:stock_quantity_left}">
        <input type="hidden" data-role="sort" name="dispersion_quantity_inc" value="{tag:dispersion_quantity_inc}">
        <input type="hidden" data-role="sort" name="dispersion_quantity_left" value="{tag:dispersion_quantity_left}">
        <input type="hidden" data-role="sort" name="consume_count" value="{tag:consume_count}">
        <input type="hidden" data-role="sort" name="consume_quantity_full" value="{tag:consume_quantity_full}">
        <input type="hidden" data-role="sort" name="consume_quantity" value="{tag:consume_quantity}">
        <input type="hidden" data-role="sort" name="units_short_name" value="{tag:units:short_name}">
    </td>
</tr>