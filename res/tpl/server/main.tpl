<div id="list_frame" class="server_stats">

    <div id="list">

        <table>
            <caption>Інформація про сервер</caption>
            <tbody>
                <tr><td class="param_name">Домен</td>               <td class="param_value"><pre>{tag:DOMAIN}</pre></td>                   <td class="param_name">Тип серверу</td>          <td class="param_value"><pre>{tag:server_server_software}</pre></td></tr>
                <tr><td class="param_name">IP серверу</td>          <td class="param_value"><pre>{tag:server_server_addr}</pre></td>       <td class="param_name">Версія серверу</td>       <td class="param_value"><pre>{tag:server_nginx_version}</pre></td></tr>
                <tr><td class="param_name">Операційна система</td>  <td class="param_value"><pre>{tag:os}</pre></td>                       <td class="param_name">Протокол з'єднання</td>   <td class="param_value"><pre>{tag:server_server_protocol}</pre></td></tr>
                <tr><td class="param_name">Користувач</td>          <td class="param_value"><pre>{tag:server_user}</pre></td>              <td class="param_name">Версія PHP</td>           <td class="param_value"><pre>{tag:phpversion}</pre></td></tr>
                <tr><td class="param_name">Домашній каталог</td>    <td class="param_value"><pre>{tag:server_home}</pre></td>              <td class="param_name">Інтерфейс</td>            <td class="param_value"><pre>{tag:php_sapi_name}</pre></td></tr>
            </tbody>
        </table>

        <table>
            <caption>Інформація про базу даних</caption>
            <tbody>
                <tr><td class="param_name">СУБД</td>                <td class="param_value"><pre>PostgreSQL</pre></td>                     <td class="param_name">Назва бази даних</td>      <td class="param_value"><pre>{tag:db:name}</pre></td></tr>
                <tr><td class="param_name">Версія СУБД</td>         <td class="param_value"><pre>{tag:db:version}</pre></td>               <td class="param_name">Розмір бази даних</td>     <td class="param_value"><pre>{tag:db:size}</pre></td></tr>
            </tbody>
        </table>

        <table>
            <caption>Налаштування PHP</caption>
            <tbody>
                <tr><td class="param_name">Date.timezone</td>       <td class="param_value"><pre>{tag:php:date_timezone}</pre></td>        <td class="param_name">Default charset</td>       <td class="param_value"><pre>{tag:php:default_charset}</pre></td></tr>
                <tr><td class="param_name">Max file uploads</td>    <td class="param_value"><pre>{tag:php:max_file_uploads}</pre></td>     <td class="param_name">Default mimetype</td>      <td class="param_value"><pre>{tag:php:default_mimetype}</pre></td></tr>
                <tr><td class="param_name">Max execution time</td>  <td class="param_value"><pre>{tag:php:max_execution_time}</pre></td>   <td class="param_name">Memory limit</td>          <td class="param_value"><pre>{tag:php:memory_limit}</pre></td></tr>
                <tr><td class="param_name">Error log</td>           <td class="param_value"><pre>{tag:php:error_log}</pre></td>            <td class="param_name">Open base dir</td>         <td class="param_value"><pre>{tag:php:open_basedir}</pre></td></tr>
            </tbody>
        </table>

        <table class="extensions">
            <caption>Розширення PHP</caption>
            <thead>
                <tr>
                    <th class="param_name">Назва</th>
                    <th class="param_value">Версія</th>
                    <th class="param_name">Назва</th>
                    <th class="param_value">Версія</th>
                    <th class="param_name">Назва</th>
                    <th class="param_value">Версія</th>
                </tr>
            </thead>
            <tbody>
                {extensions}
            </tbody>
        </table>

    </div>


</div>