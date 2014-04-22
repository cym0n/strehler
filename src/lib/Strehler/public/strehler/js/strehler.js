function subcategories(cat, subcat)
{
    var option = $("#category_selector").attr('rel');
    url = "/admin/category/select/"+cat;
    if(option)
    {
        url = url+'?option='+option;
    }
    var request = $.ajax({
        url: url,
        dataType: 'text',
    });
    request.done(function(msg) {
        if(msg == 0)
        {
            $("#subcat").parent("div").hide();
            $('#subcat').val(null);
        }
        else
        {
            $("#subcat").parent("div").show();
            $("#subcat").html(msg);
            if(subcat)
            {
                $("#subcat").val(subcat);
            }
            else
            {
                $('#subcat').val(null);
            }
        }
    });
}



function category_init(cat, subcat)
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
    });
    if(cat)
    {
        subcategories(cat, subcat);
    }
    else
    {
        $("#subcat").parent("div").hide();
    }
    category_commander(cat, subcat);
};
function category_commander(cat, subcat)
{
    if(! cat)
    {
        cat = $("#category_selector").val();
    }
    if(! subcat)
    {
        subcat = $("#subcat").val();
    }
    if(! cat)
    {
        $("#subcat").parent("div").hide();
        $('#subcat').val(null);
    }
    else
    {
        if(! subcat)
        {
            subcategories(cat, subcat);
        }
    }
    $("#category_selector").on("change", subcat_manager);
}
function subcat_manager()
{
    var category = $("#category_selector").val(); 
    if(category)
    {
        subcategories(category);
    }
    else
    {
        $("#subcat").parent("div").hide();
        $('#subcat').val(null);
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
        if($('#subcat').val() == '*')
        {
            return "anc:"+$('#category_selector').val();
        }
        else
        {
            return $('#subcat').val();
        }
    }
}

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

