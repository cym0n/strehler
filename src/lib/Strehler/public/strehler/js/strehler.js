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
    var category;
    if ($("#category_selector").length > 0)
    {
        if($("#subcat").val())
        {
            category = $("#subcat").val();
        }
        else
        {
            category = $("#category_selector").val();   
        }
        if(category)
        {
            url = "/admin/"+item_type+"/lastchapter/"+category;
        }
        else
        {
            alert("No category selected")
            return false;
        }
    }
    else
    {
        url = "/admin/"+item_type+"/lastchapter/";
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


function category_info(query, input, func)
{
    var url = '/admin/category/info';
    var data = 'query='+query+'&input='+input;
    var request = $.ajax({
        url: url,
        data: data,
    });
    request.done(function(msg) {
        func(msg);
    });
}
function get_data_for_category( event )
{
    var query;
    var input;
    $('#category-loader').show();
    if(event == null)
    {
        query = 'id';
        input = $('#category').val();
        starting_category = $('#category').val();
    }
    else
    {
        if(event.data.origin == 'combo')
        {
            query = 'id';
            input = $('#category-combo').val();
        }
        else if(event.data.origin == 'input')
        {
            query = 'name';
            input = $('#category-name').val();
        }
        else if(event.data.origin == 'parent')
        {
            query = 'id';
            input = $('#category-parent').val();
        }
    }
    category_info(query, input, update_category_box);
}
function update_category_box(msg)
{
    $('#category-name').val(msg.ext_name);
    $('#category-combo').html(msg.select);
    if(msg.subcategories == 0)
    {
        $('#category-combo').prop('disabled', true);
    }
    else
    {
        $('#category-combo').prop('disabled', false);
    }   
    $('#category').val(msg.id).trigger("change");
    $('#category-parent').val(msg.parent);
    $('#category-loader').hide();
}
