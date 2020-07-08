chem['stats_consume'] = new function()
{
    this.build_compare_stacked_column = function( table_data, chart_area )
    {
        var units = {};
        var categories = [];
        var series =
        [
            {
                "color": '#FF3300',
                "name": 'Використано',
                "data": []
            },
            {
                "color": '#006699',
                "name": 'В лабораторії',
                "data": []
            },
            {
                "color": '#FFCC00',
                "name": 'На складі',
                "data": []
            }
        ];

        table_data.find( 'tr.data' ).each( function()
        {
            // name="reagent_name"
            // name="stock_quantity_left"
            // name="dispersion_quantity_left"
            // name="consume_quantity_full"
            categories.push( { "name": $(this).find('input[name="reagent_name"]').val(), "units": $(this).find('input[name="units_short_name"]').val() } );

            series[0]["data"].push( parseFloat($(this).find('input[name="consume_quantity_full"]').val()) );
            series[1]["data"].push( parseFloat($(this).find('input[name="dispersion_quantity_left"]').val()) );
            series[2]["data"].push( parseFloat($(this).find('input[name="stock_quantity_left"]').val()) );
        } );

        chart_area.css( 'height', ( categories.length * 30 )+'px' );

        Highcharts.chart( chart_area.attr('id'), {
            "chart": {
                "type": 'bar'
            },
            "title": false,
            "xAxis": {
                "categories": categories,
            "labels":
            {
                "formatter": function ()
                {
                    return this.value["name"];
                }
            }
            },
            "yAxis": {
                "min": 0,
                "title": false
            },
            "tooltip":
            {
                formatter: function()
                {
                    var curr_units = this.x["units"];
                    var label = '<span>'+this.x["name"]+'</span>';
                        label = label + '<br>';

                    this["points"].forEach(function( item, i, arr )
                    {
                        // style="color:'+arr[i]['point']['color']+'"
                        label = label + '<span>'+arr[i]['series']['name']+'</span>: <b>'+arr[i]['point']['y']+' '+curr_units+'</b><br>';
                    });
                    return '<div class="table02chart_tooltip">'+label+'</div>';
                },
                "shared": true
            },
            "plotOptions": {
                "bar": {
                    "stacking": 'percent'
                },
                "series": {
                    "borderWidth": 0,
                    "dataLabels": false
                    /*{
                        "enabled": true,
                        "format": '{point.y:.1f}%'
                    }*/
                }
            },
            "series": series
        });
    }

    this.build_compare_round_chartt = function( table_data, chart_area )
    {
        var series = [];

        table_data.find( 'tr.data.group_start [scope="rowgroup"]' ).each( function()
        {
            series.push
            (
                {
                    "name":$(this).attr('data-title'),
                    "y": parseInt( $(this).attr('data-consume_count_summ') )
                }
            );
        });

        Highcharts.chart(chart_area.attr('id'), {
            "chart": {
                "plotBackgroundColor": null,
                "plotBorderWidth": null,
                "plotShadow": false,
                "type": 'pie'
            },
            "title": false,
            "tooltip": false,
            "plotOptions": {
                "pie": {
                    "allowPointSelect": true,
                    "cursor": 'pointer',
                    "dataLabels": {
                        "enabled": true,
                        "format": '<b>{point.name}</b>: {point.y:.0f}'
                    }
                }
            },

            "series": [{
                "name": 'Brands',
                "size": '160%',
                "center": ['50%', '87%'],
                "startAngle": -100,
                "endAngle": 100,
                "colorByPoint": true,
                "data": series
            }]
        });

    }
}


$(document).ready( function()
{
    chem.stats_consume.build_compare_round_chartt( $('#table03'), $('#table03chart') );
    chem.stats_consume.build_compare_stacked_column( $('#table02'), $('#table02chart') );
});