<div class="line" data-hash="{tag:using:hash}">

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
                [reactive]<span class="recipe_name">{tag:recipe:name} ({tag:reactive:quantity_inc} {tag:units:short_name})</span>[/reactive]
            </td>
            <td class="expert">{tag:user:surname} {tag:user:name} {tag:user:phname}</td>
            <td class="consume">{consume:list}<div class="clear"></div></td>
            <td></td>
        </tr>
    </table>
</div>