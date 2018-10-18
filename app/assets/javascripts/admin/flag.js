$(document).ready(function() {
	var dataform;
	$('.on-flag').click(function(event) {

		var flag_name = $('.flag-name').html();
		var flag_value = $('.flag-value').html();
		name = flag_name.replace('\t', '');
		value = flag_value.replace('\t', '');

		dataform = {
			'flag_name': flag_name,
			'flag_value': flag_value
		}

		$(this).addClass('active');
		$('.off-flag').removeClass('active');

		exec(dataform);
		event.preventDefault();
	});

	var flag_val = $('.flag-value').html();

	if (flag_val == 1) {
		$('.on-flag').addClass('active');
	}

	if (flag_val == 0) {
		$('.off-flag').addClass('active');
	}

	$('.off-flag').click(function(event) {
		$(this).addClass('active');
		$('.on-flag').removeClass('active');

		var flag_name = $('.flag-name').html();
		var flag_value = $('.flag-value').html();
		name = flag_name.replace('\t', '');
		value = flag_value.replace('\t', '');

		dataform = {
			'flag_name': flag_name,
			'flag_value': flag_value
		}

		exec_off(dataform);
		event.preventDefault();
	});

	function exec(data){
      $.ajax({
        url: '/admin/flags/on_flag',
        type: 'POST',
        dataType: 'json',
        data: {data_text: data},

        success: function(response) {
          if(response){
          	$('.flag-value').html('1');
          }
        },
     });
  	}

  	function exec_off(data){
      $.ajax({
        url: '/admin/flags/off_flag',
        type: 'POST',
        dataType: 'json',
        data: {data_text: data},

        success: function(response) {
          if(response){
          	$('.flag-value').html('0');
          }
        },
     });
  	}
});
