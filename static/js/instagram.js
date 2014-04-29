$(document).ready(function() {
	if (len($('.instagram_photo') > 0)){
		var URL = 'https://api.instagram.com/v1/locations/IDHERE/media/recent?access_token='
		$.ajax({
			type: "GET",
			url: URL,
			cache: false,
			dataType:'jsonp',
			success: function(data){
				$.each(data.data.items, function(index) {
					console.log('a');
				});
			}
		});
	}
	
});
