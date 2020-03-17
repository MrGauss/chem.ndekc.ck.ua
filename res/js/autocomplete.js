var autocomplete = new function()
{
    this._STILL_SORT = false;
    this.menuItemAnimation = false;

    this.init = function( obj )
    {
        obj.attr( 'autocomplete', true );
        obj.find('[data-autocomplete="1"]').on( 'keyup',    function(){ autocomplete.init_single( $(this), false ); } );
    }

    this.init_single = function( obj, showTOP10 )
    {
        if( !obj.hasClass('autocomplete') ){ obj.addClass('autocomplete'); }else{ return false; }

        showTOP10 = parseInt( showTOP10 ) ? true : false;
        if( showTOP10 ){ obj.val( 'some shit' ); }



        obj.autocomplete({
            "minLength":    1,
            "highlight":    false,
            "close":        function(){ obj.removeClass('autocomplete'); },
            "source":       function( request, response )
                            {
                                var post = {};
                                    post['ajax']        = 1;
                                    post['action']      = 1;
                                    post['subaction']   = 1;
                                    post['term']        = request.term;
                                    post['mod']         = 'autocomplete';

                                    post['key']         = obj.attr('data-key');
                                    post['table']       = obj.attr('data-table');
                                    post['column']      = obj.attr('data-column');
                                    post['top10']       = showTOP10;

                                if( request.term && request.term.length > 1 )
                                {
                                    $.ajax({ data: post }).done(function( _r )
                                    {
                                        _r = chem.txt2json( _r );
                                        response( _r["reslt"] );
                                    });
                                }
                            }
        });

        /*
        $.ui.autocomplete.prototype._renderItem = function (ul, item)
        {
            var t = String(item.label).replace( ":EXPERTISE:" , '<span class="ui-state-expertise" title="Дані взято з розділу експертиз">ЕКСП:</span>');
            return $("<li></li>")
                .data("item.autocomplete", item)
                .append("<div>" + t + "</div>")
                .appendTo(ul);
        };
        */
    }
}