function evoke_subcategories(event)
{
    subcategories(null);
}
function maincategories(cat, subcat)
{
    var request = $.ajax({
        url: "/admin/category/select",
        dataType: 'text',
    });
    request.done(function(msg) {
       $("#category_selector").html(msg);
       if(cat)
       {
            $("#category_selector").val(cat);
       }
       category_init(subcat);
    });
}
function subcategories(subcat) { 
        var category = $("#category_selector").val(); 
        if(category)
        {
            var request = $.ajax({
            url: "/admin/category/select/"+category,
            dataType: 'text',
            });
            request.done(function(msg) {
                if(msg == '0')
                {
                    $("#subcat").parent("div").hide();
                    $('#subcat').val(null);
                }
                else
                {
                    $("#subcat").parent("div").show();
                    $('#subcat').html(msg);
                    console.dir(subcat);
                    if(subcat)
                    {
                        $('#subcat').val(subcat);
                    }
                }
            });
        }   
};
function get_final_category()
{
    if((! $('#subcat').val()) || (! $('#subcat').is(":visible")))
    {
        return $('#category_selector').val();
    }
    else
    {
        return $('#subcat').val();
    }
}
function category_init(subcat) {
    $("#category_selector").on("change", evoke_subcategories);
    if(! $('#subcat').val())
    {
        if($('#category_selector').val())
        {
            subcategories(subcat);
        }
        else
        {
            $("#subcat").parent("div").hide();
        }
    }
};
function tags_refresh_on_parent() {
    category = $("#category_selector").val()
    var request = $.ajax({
        url: "/admin/category/tagform/"+item_type+"/"+category,
        dataType: 'text',
    });
    request.done(function(msg) {
        $('#tags-place').html(msg);
    });
};
function tags_refresh_on_sub() {
    category = $("#subcat").val();
    if(! category)
    {
        category = $("#category_selector").val()
    }
    var request = $.ajax({
        url: "/admin/category/tagform/"+item_type+"/"+category,
        dataType: 'text',
    });
    request.done(function(msg) {
        $('#tags-place').html(msg);
    });
};
function tags_refresh_on_id(id) {
    var request = $.ajax({
        url: "/admin/"+item_type+"/tagform/"+id,
        dataType: 'text',
    });
    request.done(function(msg) {
        $('#tags-place').html(msg);
    });
};
function tags_init(id)
{
    $("#category_selector").on("change", tags_refresh_on_parent);
    $("#subcat").on("change", tags_refresh_on_sub);
    if(id)
    {
        tags_refresh_on_id(id)
    }
    else
    {
        tags_refresh_on_parent();
    }
}
function get_last_chapter() {
    var category;
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
        var request = $.ajax({
                               url: "/admin/"+item_type+"/lastchapter/"+category,
                               dataType: 'text',
                            });
        request.done(function(msg) {
                                    $('#order').val(msg);
                                   });    
    }
    else
    {
        $('#order').val(null); 
    }
}

