chem['stats_consume_dynamic'] = new function()
{
    this.build_chart = function( table_data, chart_area )
    {
        // table_data - OBJECT
        // chart_area - OBJECT

        var categories = [ 'ѳ����', '�����', '��������', '������', '�������', '�������', '������', '�������', '��������', '�������', '��������', '�������' ];
        var series =
        [
            {
                "name": '������������ ������� �� ��������',
                "data": [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
                "type": 'column'

            }
        ];
        var data_lines = 0;


        table_data.find('tr.data').each( function()
        {
            var i = 0;
            var cval = 0;
            var cmax = parseFloat( $(this).find('[data-role="full"]').attr( 'data-value' ) );
            var prc  = cmax / 100;

            for (let i = 0; i < 12; i++)
            {
                cval = parseFloat( $(this).find('[data-role="data"][data-group="' + ( i + 1 ) + '"]').attr( 'data-value' ) );
                series[0]["data"][i] = series[0]["data"][i] + ( cval / prc );
            }
            data_lines++;
        });

        var i = 0;
        for (let i = 0; i < 12; i++) {
            series[0]["data"][i] = series[0]["data"][i] / data_lines;
        }


        chem.stats_consume_dynamic.init_chart( chart_area, categories, series );


    }

    this.init_chart = function( chart_area, categories, series )
    {
            Highcharts.chart( chart_area.attr( 'id' ),
            {
                "chart":
                {
                    "type": 'column'
                },
                "title": false,
                "subtitle": false,
                "xAxis":
                {
                    "categories": categories,
                    "crosshair": true
                },
                "yAxis":
                {
                    "min": 0,
                    //"max": 100,
                    "title": { "text": '������������ �� �������� ������� (%)' }
                },
                "tooltip": false,
                /*{
                    "headerFormat": '<span style="font-size:10px">{point.key}</span><table>',
                    "pointFormat": '<tr><td style="color:{series.color};padding:0">{series.name}: </td><td style="padding:0"><b>{point.y:.1f} mm</b></td></tr>',
                    "footerFormat": '</table>',
                    "shared": true,
                    "useHTML": true
                },*/
                "plotOptions":
                {
                    "column":
                    {
                        "pointPadding": 0.2,
                        "borderWidth": 1,
                        "shadow": true,
                        "color": '#3399CC',
                        "borderColor": '#333333'
                    },
                    "series": {
                        "borderWidth": 0,
                        "dataLabels": {
                            "enabled": true,
                            "format": '{point.y:.1f}%'
                        }
                    }
                },
                "series": series
            });
    }

}

$(document).ready( function()
{
    chem.stats_consume_dynamic.build_chart( $('#table01'), $('#table01_chart') );
});