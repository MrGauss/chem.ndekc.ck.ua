<div class="line {tag:not_used_class}" data-id="{tag:id}" data-is_precursor="{tag:is_precursor}" data-inc_date="{tag:inc_date_unix}" data-lifetime="{tag:lifetime}" data-quantity_inc="{tag:quantity_inc}" data-quantity_left="{tag:quantity_left}" data-not_used_perc="{tag:not_used_perc}">

    <input type="hidden" data-role="sort" name="reagent" value="{tag:reagent:name}">
    <input type="hidden" data-role="sort" name="number" value="{tag:reagent_number:1}-{tag:reagent_number:0}">
    <input type="hidden" data-role="sort" name="inc_date" value="{tag:inc_date_unix}">
    <input type="hidden" data-role="sort" name="quantity_inc" value="{tag:quantity_inc}">
    <input type="hidden" data-role="sort" name="quantity_left" value="{tag:quantity_left}">
    <input type="hidden" data-role="sort" name="out_expert" value="{tag:out_expert_surname} {tag:out_expert_name} {tag:out_expert_phname}">

    <table>
        <tr>
            <td class="numi">{tag:numi}</td>
            <td class="reagent">{tag:reagent:name}</td>
            <td class="number">{tag:reagent_number}</td>
            <td class="inc_date">{tag:inc_date}</td>
            <td class="quantity_inc">{tag:quantity_inc}  {tag:reagent_units_short}</td>
            <td class="quantity_left">{tag:quantity_left} {tag:reagent_units_short}</td>
            <td class="out_expert">{tag:out_expert_surname} {tag:out_expert_name} {tag:out_expert_phname}</td>
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
    <div class="precursor_label">Прекурсор</div>
</div>