
function getNotifications(){
	
	if ($('.notifyContent .notifyItem').length == 0){
		var userid = $.cookie('userid');
		
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