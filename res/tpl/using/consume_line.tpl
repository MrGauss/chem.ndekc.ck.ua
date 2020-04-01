            <div class="consume"
                    data-consume_hash="{tag:consume_hash}"
                    data-dispersion_id="{tag:dispersion_id}"
                    data-key="{tag:key}"
            >
                <table>
                    <tr>
                        <td class="name">
                            <div class="reagent_name_fr">
                                <span class="reagent_name">{tag:reagent:name}</span>
                                <span class="reagent_number">[{tag:reagent_number}]</span>
                            </div>
                        </td>
                        <td class="quantity">
                            <div class="quantity_fr">
                                <input class="input" name="consume_quantity" type="number" min="0" step="0.1" maxlength="10" max="{tag:dispersion_quantity_left}" value="{tag:quantity}" data-mask="999999.99999" data-placeholder="" placeholder="">
                                <input class="input" name="units_short_name" type="text" value="{tag:reagent:units:short_name}">
                            </div>
                        </td>
                    </tr>
                </table>
            </div>