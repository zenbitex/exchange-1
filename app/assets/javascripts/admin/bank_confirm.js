$(document).ready(function(){
	$(".check_list input:checkbox").click(function(){

		console.log(is_all_check());

		if (is_all_check()) {
			$("#send_jpy_bank").attr("disabled", false);
		}else {
			$("#send_jpy_bank").attr("disabled", true);
		}
	})

	function is_all_check() {
		var is_check = true;
		var $check_list = $(".check_list input:checkbox");
		$check_list.each(function(){
			if (!$(this).is(':checked')) {
				is_check = false;
			}
		});

		return is_check;
	}

});
