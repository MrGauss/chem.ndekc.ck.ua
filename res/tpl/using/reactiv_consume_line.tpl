            <div class="consume"
                    data-consume_hash="{consume:consume_hash}"
                    data-reactiv_hash="{consume:reactiv_hash}"
                    data-key="{consume:key}"
            >
                <table>
                    <tr>
                        <td class="name">
                            <div class="reagent_name_fr">
                                <span class="reagent_name">{consume:recipe:name}</span>
                                <span class="reagent_number">Ç³ïñóºòüñÿ: <b class="cooked_dead_date">{consume:reactiv_dead_date}</b></span>
                            </div>
                        </td>
                        <td class="quantity">
                            <div class="quantity_fr">
                                <input class="input" name="consume_quantity" type="number" min="0" step="0.1" maxlength="10" max="{consume:reactiv_quantity_left}" value="{consume:quantity}" data-mask="999999.99999" data-placeholder="" placeholder="">
                                <input class="input" name="units_short_name" type="text" value="{consume:units:short_name}">
                            </div>
                        </td>
                    </tr>
                </table>
                <div class="remove"></div>
            </div>
