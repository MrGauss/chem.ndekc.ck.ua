            <div class="consume"
                    data-consume_hash="{tag:consume_hash}"
                    data-reactiv_hash="{tag:reactiv_hash}"
                    data-key="{tag:key}"
            >
                <table>
                    <tr>
                        <td class="name">
                            <div class="reagent_name_fr">
                                <span class="reagent_name">{cooked:reactiv_name}</span>
                                <span class="reagent_number">Ç³ïñóºòüñÿ: <b>{cooked:dead_date}</b></span>
                            </div>
                        </td>
                        <td class="quantity">
                            <div class="quantity_fr">
                                <input class="input" name="consume_quantity" type="number" min="0" step="0.1" maxlength="10" max="{cooked:quantity_inc}" value="{tag:quantity}" data-mask="999999.99999" data-placeholder="" placeholder="">
                                <input class="input" name="units_short_name" type="text" value="{cooked:units:short_name}">
                            </div>
                        </td>
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
{tag:dispersion_quantity_left}
{tag:dispersion_quantity_inc}
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

{cooked:hash}
{cooked:reactiv_menu_id}
{cooked:quantity_inc}
{cooked:quantity_left}
{cooked:inc_expert_id}
{cooked:group_id}
{cooked:inc_date}
{cooked:dead_date}
{cooked:safe_place}
{cooked:safe_needs}
{cooked:comment}
{cooked:using_hash}
{cooked:reactiv_name}
{cooked:reactiv_units_id}
{cooked:reactiv_comment}
{cooked:purpose_id}
{cooked:inc_date_unix}
{cooked:dead_date_unix}
{cooked:units:id}
{cooked:units:name}
{cooked:units:position}
{cooked:units:short_name}

-->