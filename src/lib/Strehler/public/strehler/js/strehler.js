function tags_refresh() {
    var id = $('#category').val();
    if(id != null)
    {
        if(id == starting_category && object_id != null)
        {
            var request = $.ajax({
                url: "/admin/"+item_type+"/tagform/"+object_id,
                dataType: 'text',
            });
            request.done(function(msg) {
                $('#tags-place').html(msg);
            });
        }
        else
        {
            var request = $.ajax({
                url: "/admin/category/tagform/"+item_type+"/"+id,
                dataType: 'text',
            });
            request.done(function(msg) {
                $('#tags-place').html(msg);
            });
        }
    }
};
function tags_init() {
    if(object_id != null)
    {
        var request = $.ajax({
            url: "/admin/"+item_type+"/tagform/"+object_id,
            dataType: 'text',
        });
        request.done(function(msg) {
            $('#tags-place').html(msg);
            $("#category").on("change", tags_refresh);
        });
    }
    else
    {
        $("#category").on("change", tags_refresh);
    }
};
function get_last_chapter() {
    var category = $("#category").val();
    if ($("#category").val() != '')
    {

        url = "/admin/"+item_type+"/lastchapter/"+category;
    }
    else
    {
        alert("No category selected")
        return false;
    }
    var request = $.ajax({
                               url: url,
                               dataType: 'text',
                         });
    request.done(function(msg) {
                                    $('#order').val(msg);
                               });    
    return false;
}
$(function() {
        $( "#list-tools" ).accordion({
            collapsible: true,
            active: false,
            activate : function (event, ui)
                   {
                       if(ui.newPanel.length == 0)
                       {
                           $('#tools-label').text("Tools")
                       }
                       else
                       {
                          $('#tools-label').text("Hide tools")
                       }
                   }
        });
  });


function category_info(query, input, category_box, func)
{
    var url = '/admin/category/info';
    var data = 'query='+query+'&input='+input;
    var option = category_box.attr('rel');
    if(option)
    {
        data = data+'&option='+option;
    }
    var request = $.ajax({
        url: url,
        data: data,
    });
    request.done(function(msg) {
        func(category_box, msg);
    });
}
function init_category_boxes()
{
    $(".category-widget").each(function ( index ) {
        var category_box = $( this );
        input = category_box.find( ".sel-category-id" ).val();
        category_info("id", input, category_box, update_category_box);
    });
}


function get_data_for_category( event )
{
    var category_box = $( event.target ).parents('div').find('.category-widget');
    var query;
    var input;
    category_box.find(".sel-category-loader").show();
    if(event.data.origin == 'combo')
    {
        query = 'id';
        input = $( event.target ).val();
    }
    else if(event.data.origin == 'input')
    {
        query = 'name';
        input = category_box.find(".sel-category-input").find(".sel-category-name").val();
    }
    else if(event.data.origin == 'parent')
    {
        query = 'id';
        input =  category_box.find(".sel-category-parent").val();
    }
    category_info(query, input, category_box, update_category_box);
}
function update_category_box(category_box, msg)
{
    category_box.find(".sel-category-name").val(msg.ext_name);

    category_combo = category_box.find(".sel-category-combo");
    category_combo.html(msg.select);
    if(msg.subcategories == 0)
    {
        category_combo.prop('disabled', true);
    }
    else
    {
        category_combo.prop('disabled', false);
    }   
    category_box.find(".sel-category-id").val(msg.id).trigger("change");
    category_box.find(".sel-category-parent").val(msg.parent);
    category_box.find(".sel-category-loader").hide();
}
