<div class="default_editor stock_editor" dara-rand="{RAND}">
    <div class="error_area dnone"></div>
    <div class="good_area dnone"></div>
    <div class="clear"></div>

    <input type="hidden" name="id" value="{tag:id}" />
    <input type="hidden" name="key" value="{tag:key}" />

    <div class="elem name">
        <label class="label">����� �������� �� ���������� ��������</label>
        <input class="input" type="text" name="name" value="{tag:name}" data-important="1" data-save="1">
    </div>

    <div class="clear"></div>

    <div class="elem units">
        <label class="label">������� �����</label>
        <select data-important="1" class="input select" data-save="1" data-value="{tag:units_id}" value="{tag:units_id}" name="units_id"><option value="0">--</option>{select:units}</select>
    </div>

    <div class="clear"></div>

    <div class="edit_info">
        ������� ����� ����� ������� <u>���</u><br>�������� ��������� ������� ������� ���������� <nobr>(��-, ����-, ���-, ����)</nobr>!
        <br>
        <br>
        ������ ��������!<br>����� ������� � ����������, ���� ����������� ���������� �������� ��� � ���������� ���� �������!
    </div>

    <div class="clear"></div>
</div>