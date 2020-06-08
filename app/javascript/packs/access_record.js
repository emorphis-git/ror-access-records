(function ($) {
  $(function() {
    $('select[name="access_record[client_id]"]').on('change', function(){    
      var id = $(this).val()
      $.ajax({
        url: 'get_project_by_client',
        dataType: 'Json',
        type : 'post',
        data : { id : id},
        success: function (msg){
          if (msg.length !== 0) {
            var opt = '<option value="">Select a Project</option>';
            $.each(msg, function (i, item) {
                opt += '<option value="' + item.id + '">' + item.name + '</option>';
            });
            $('select[name="access_record[project_id]"]').html(opt);
          } else
          {
            var opt = '<option value="">Select a Project</option>';
            $('select[name="access_record[project_id]"]').html(opt);
          }
        }
      })
    });

    $('#showPassword').on('click',function(){
      var type = $('#password').children().attr('type');
      if(type == 'password'){
        $('#password').children().attr('type','text');
        $(this).removeClass('icon-unwatched').addClass('icon-watched');
      }else{
        $('#password').children().attr('type','password');
        $(this).removeClass('icon-watched').addClass('icon-unwatched');
      }

    });
 
  });

}(jQuery));