function subcategories() { 
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
                }
            });
        }   
        else
        {
            $('#image_preview').attr('src', '/strehler/images/no-image.png');
        }
};
function category_init() {
    if(! $('#subcat').val())
    {
        if($('#category_selector').val())
        {
            subcategories();
        }
        else
        {
            $("#subcat").parent(".select").hide();
        }
    }
    $("#category_selector").on("change", subcategories);
};
