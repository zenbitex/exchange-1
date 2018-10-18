$(function(){
	$('.poup-chat').show();
	$('.chat-content').removeClass('active');
	$('.poup-chat').click(function() {
		$('.chat-content').addClass('active');
		$('.poup-chat').hide();
	});

	$('.name-room').click(function() {
		$('.chat-content').removeClass('active');
		$('.poup-chat').show();
	})
});