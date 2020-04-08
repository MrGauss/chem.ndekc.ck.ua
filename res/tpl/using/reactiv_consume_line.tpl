            <div class="consume"
                    data-consume_hash="{tag:consume_hash}"
                    data-reactiv_hash="{tag:reactiv_hash}"
                    data-key="{tag:key}"
            >
                <table>
                    <tr>
                        <td class="name">
                            <div class="reagent_name_fr">
                                <span class="reagent_name">{tag:reagent:name}</span>
                                <span class="reagent_number">Ç³ïñóºòüñÿ: <b class="cooked_dead_date">{cooked:dead_date}</b></span>
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
                <div class="remove"></div>
            </div>
