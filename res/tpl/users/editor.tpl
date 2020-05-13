<div id="user_editor" class="default_editor user_editor">
    <input type="hidden" name="id" value="{tag:id}" data-save="1" />
    <input type="hidden" name="key" value="{tag:key}" data-save="1" />

    <div class="elem login">
        <label class="label">Логін</label>
        <input class="input" type="text" name="login" value="{tag:login}" data-save="0" data-important="0" disabled="disabled" maxlength="32">
    </div>

    <div class="elem password">
        <label class="label">Пароль</label>
        <input class="input" type="text" name="password" value="" data-save="0" data-important="0" readonly="readonly" maxlength="32" placeholder="Клікніть двічі щоб змінити" >
    </div>

    <div class="elem surname">
        <label class="label">Прізвище</label>
        <input class="input" type="text" name="surname" value="{tag:surname}" data-save="1" data-important="1"  maxlength="24">
    </div>

    <div class="elem name">
        <label class="label">І'мя</label>
        <input class="input" type="text" name="name" value="{tag:name}" data-save="1" data-important="1"  maxlength="16">
    </div>

    <div class="elem phname">
        <label class="label">По батькові</label>
        <input class="input" type="text" name="phname" value="{tag:phname}" data-save="1" data-important="1"  maxlength="24">
    </div>

    [access:users:lab]
    <div class="elem lab">
        <label class="label">Лабораторія</label>
        <select class="input select" data-save="1" data-value="{tag:group_id}" value="{tag:group_id}" name="group_id" data-important="1"><option value="0">--</option>{list:labs}</select>
    </div>
    [/access]

    [access:users:access]
    <div class="elem access">
        <label class="label">Рівень доступу</label>
        <select class="input select" data-save="1" data-value="{tag:access_id}" value="{tag:access_id}" name="access_id" data-important="1"><option value="0">--</option>{list:access}</select>
    </div>
    [/access]

</div>