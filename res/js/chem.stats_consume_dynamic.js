chem['stats_consume_dynamic'] = new function()
{
    this.build_compare_diff_chart = function( table_01_data, table_02_data, chart_area )
    {
        var categories = [ 'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень', 'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень' ];
        var ser =
        [
            {
                "name": 'Різниця використання речовин та матеріалів',
                "data": [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ]
                //"color": '#009900'
            }
        ];
        var series =
        [
            {
                "name": 'Використання речовин та матеріалів (минулий рік)',
                "data": [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
                "type": 'column',
                "color": '#009900'

            },
            {
                "name": 'Використання речовин та матеріалів (поточний рік)',
                "data": [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
                "type": 'column',
                "color": '#FF6600'

            }
        ];
        var data_lines = 0;


        table_02_data.find('tr.data').each( function()
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


        data_lines = 0;

        table_01_data.find('tr.data').each( function()
        {
            var i = 0;
            var cval = 0;
            var cmax = parseFloat( $(this).find('[data-role="full"]').attr( 'data-value' ) );
            var prc  = cmax / 100;

            for (let i = 0; i < 12; i++)
            {
                cval = parseFloat( $(this).find('[data-role="data"][data-group="' + ( i + 1 ) + '"]').attr( 'data-value' ) );
                series[1]["data"][i] = series[1]["data"][i] + ( cval / prc );
            }
            data_lines++;
        });

        var i = 0;
        for (let i = 0; i < 12; i++) {
            series[1]["data"][i] = series[1]["data"][i] / data_lines;
        }

        var i = 0;

        var max = 0;

        for (let i = 0; i < 12; i++)
        {
            ser[0]["data"][i] = series[1]["data"][i] - series[0]["data"][i];

            if( Math.abs(ser[0]["data"][i]) > max ){ max = Math.abs(ser[0]["data"][i]); }

        }

        max = max + max / 10;

        Highcharts.chart( chart_area.attr('id') ,
        {
            "chart":
            {
                "type": 'column'
            },
            "title": false,
            "yAxis":
            {
                "title": false,
                "crosshair": true,
                "max": max,
                "min": ( max * -1 ),
            },
            "xAxis":
            {
                "categories": categories,
                "crosshair": true
            },
            "credits":
            {
                "enabled": false
            },
            "series": ser,
            "tooltip": false,
            "plotOptions":
            {
                "column":
                {
                    "pointPadding": 0.2,
                    "borderWidth": 1,
                    "shadow": true,
                    "color": '#750000',
                    "borderColor": '#FFFFFF'
                },
                "series":
                {
                    "borderWidth": 0,
                    "dataLabels":
                    {
                        "enabled": true,
                        "format": '{point.y:.1f}%'
                    },
                    "zones": [{ "value": 0, "className": 'zone-0' }, { "value": 100, "className": 'zone-1' }],
                }

            }
        });
    }

    this.build_compare_chart = function( table_01_data, table_02_data, chart_area )
    {
        var categories = [ 'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень', 'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень' ];
        var series =
        [
            {
                "name": 'Використання речовин та матеріалів (минулий рік)',
                "data": [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
                "type": 'column',
                "color": '#555555'

            },
            {
                "name": 'Використання речовин та матеріалів (поточний рік)',
                "data": [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ],
                "type": 'column',
                "color": '#FF6600'

            }
        ];
        var data_lines = 0;

        table_02_data.find('tr.data').each( function()
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


        data_lines = 0;

        table_01_data.find('tr.data').each( function()
        {
            var i = 0;
            var cval = 0;
            var cmax = parseFloat( $(this).find('[data-role="full"]').attr( 'data-value' ) );
            var prc  = cmax / 100;

            for (let i = 0; i < 12; i++)
            {
                cval = parseFloat( $(this).find('[data-role="data"][data-group="' + ( i + 1 ) + '"]').attr( 'data-value' ) );
                series[1]["data"][i] = series[1]["data"][i] + ( cval / prc );
            }
            data_lines++;
        });

        var i = 0;
        for (let i = 0; i < 12; i++) {
            series[1]["data"][i] = series[1]["data"][i] / data_lines;
        }

        chem.stats_consume_dynamic.init_chart( chart_area, categories, series );
    }

    this.build_chart = function( table_data, chart_area )
    {
        // table_data - OBJECT
        // chart_area - OBJECT

        var categories = [ 'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень', 'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень' ];
        var series =
        [
            {
                "name": 'Використання речовин та матеріалів',
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
                    "title": { "text": 'Використання від загальної кількості (%)' }
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
    chem.stats_consume_dynamic.build_chart( $('#table02'), $('#table02_chart') );
    chem.stats_consume_dynamic.build_compare_chart( $('#table01'), $('#table02'), $('#compare_chart') );
    chem.stats_consume_dynamic.build_compare_diff_chart( $('#table01'), $('#table02'), $('#compare_diff_chart') );
});