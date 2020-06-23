<div class="line {tag:not_used_class}" data-hash="{tag:hash}" data-lifetime="{tag:lifetime}" data-quantity_inc="{tag:quantity_inc}" data-quantity_left="{tag:quantity_left}" data-not_used_perc="{tag:not_used_perc}">

    <input type="hidden" data-role="sort" name="reagent" value="{tag:menu:name}">
    <input type="hidden" data-role="sort" name="inc_date" value="{tag:inc_date_unix}">
    <input type="hidden" data-role="sort" name="dead_date" value="{tag:dead_date_unix}">
    <input type="hidden" data-role="sort" name="quantity_inc" value="{tag:quantity_inc}">
    <input type="hidden" data-role="sort" name="quantity_left" value="{tag:quantity_left}">

    <table>
        <tr>
            <td class="numi">{tag:numi}</td>
            <td class="name">{tag:menu:name}</td>
            <td class="inc_date">{tag:inc_date}</td>
            <td class="dead_date">{tag:dead_date}</td>
            <td class="quantity_inc">{tag:quantity_inc} {tag:units:short_name}</td>
            <td class="quantity_left">{tag:quantity_left} {tag:units:short_name}</td>
            <td class="composition">{tag:composition:html}</td>
            <td></td>
        </tr>
    </table>
    <div class="lifetime_label lf_gone">Реактив зіпсувався</div>
    <div class="lifetime_label lf_today">Реактив зіпсується сьогодні</div>
    <div class="lifetime_label lf_1day">Реактив скоро зіпсується</div>

    <div class="using_perc fully_used">Закінчився</div>
    <div class="using_perc almost_used">Закінчується</div>
    <!-- div class="using_perc half_used">Не дохуя, але є</div -->
    <!-- div class="using_perc not_used">Ще дохуя</div -->
</div>