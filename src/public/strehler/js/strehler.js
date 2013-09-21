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
                    $("#subcat").parent(".select").hide();
                }
                else
                {
                    $("#subcat").parent(".select").show();
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
    if(! $('#subcat').val())
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
            $("#subcat").parent(".select").hide();
        }
    }
};
