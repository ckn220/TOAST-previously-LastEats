
function getNotifications(){
	
	if ($('.notifyContent .notifyItem').length == 0){
		var userid = $.cookie('userid');
		
		$('.icon.notify').removeClass('active');
		$('.icon.notify .userNotifyCount').remove();
		
		$.ajax({
			url: 'notify_content',
			type: "post",
			data: {'userid': userid},
			success: function(value) {
				$('.notifyContent').html('');
				$('.notifyContent').append(value);
			}
		});
	}
}