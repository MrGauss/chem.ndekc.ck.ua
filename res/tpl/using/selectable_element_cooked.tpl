<div class="line" data-hash="{tag:hash}" data-lifetime="{tag:lifetime}" data-quantity_inc="{tag:quantity_inc}" data-quantity_left="{tag:quantity_left}" data-not_used_perc="{tag:not_used_perc}" data-units="{tag:units:short_name}">
    <table>
        <tr>
            <td class="reagent">
                <span class="name">{tag:menu:name}</span>
                <span class="quantity_left">Залишилось: {tag:quantity_left} {tag:units:short_name}</span>
            </td>
            <td class="date">
                <span class="inc_date"><label>Приготовано:</label><b>{tag:inc_date}</b></span>
                <span class="dead_date"><label>Зіпсується:</label><b>{tag:dead_date}</b></span>
            </td>
            <!-- td class="composition">{tag:com position:html}</td -->
        </tr>
    </table>
    <div class="expert" data-expert_id="{tag:inc_expert_id}">Приготував: {tag:user:surname} {tag:user:name:1}.{tag:user:phname:1}.</div>
</div>

<!--
    data-hash="{tag:hash}"
    data-lifetime="{tag:lifetime}"
    data-quantity_inc="{tag:quantity_inc}"
    data-quantity_left="{tag:quantity_left}"
    data-not_used_perc="{tag:not_used_perc}"
-->