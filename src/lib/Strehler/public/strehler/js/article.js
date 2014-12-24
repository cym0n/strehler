function manage_preview() { 
    var image = $("#image_selector").val(); 
    if(image)
    {
        var request = $.ajax({
            url: "/admin/image/src/"+image,
            dataType: 'text',
            });
        request.done(function(msg) {
            $('#image_preview').attr('src', msg);
        });
    }   
    else
    {
        $('#image_preview').attr('src', '/strehler/images/no-image.png');
    }
}    
$(document).ready(function() {
        manage_preview();
        $("#image_selector").on("change", manage_preview);
});
