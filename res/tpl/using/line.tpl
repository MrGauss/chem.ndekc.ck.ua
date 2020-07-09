<div class="line" data-hash="{tag:using:hash}" data-purpose="{tag:purpose:attr}">

    <input type="hidden" data-role="sort" name="date" value="{tag:using:date_unix}">
    <input type="hidden" data-role="sort" name="purpose_id" value="{tag:purpose:id}">
    <input type="hidden" data-role="sort" name="result" value="[reactive]{tag:recipe:name}[/reactive]">
    <input type="hidden" data-role="sort" name="expert" value="{tag:user:surname} {tag:user:name} {tag:user:phname}">

    <table>
        <tr>
            <td class="numi">{tag:using:numi}</td>
            <td class="date">{tag:using:date}</td>
            <td class="purpose_name">{tag:purpose:name}</td>
            <td class="name">
                <!-- reactiv:3     -->  [purpose:3]<span class="recipe_name">{tag:recipe:name} ({tag:reactive:quantity_inc} {tag:units:short_name})</span>[/purpose]
                <!-- maintenance:2 -->  [purpose:2]<span class="recipe_name">{tag:using:tech_info}</span>     [/purpose]
                <!-- expertise:1   -->  [purpose:1]<span class="recipe_name">{tag:using:exp_number}</span>    [/purpose]
                <!-- other:4   -->      [purpose:4]<span class="recipe_name">{tag:using:tech_info}</span>     [/purpose]
                <!-- science:5   -->    [purpose:5]<span class="recipe_name">{tag:using:tech_info}</span>     [/purpose]
                <!-- science:5   -->    [purpose:6]<span class="recipe_name">{tag:using:tech_info}</span>     [/purpose]
            </td>
            <td class="expert">{tag:user:surname} {tag:user:name} {tag:user:phname}</td>
            <td class="consume">{consume:list}<div class="clear"></div></td>
            <td></td>
        </tr>
    </table>
</div>