

$(document).ready(function(){
	setTimeout(function(){
		$(window).scroll(function(){
			console.log($('.ui-page').height() - ($('body').scrollTop() + $('body').height()));
			if ($('.ui-page').height() - ($('body').scrollTop() + $('body').height()) < 500){
				get_newsfeed(lastType);
			}
		});
	},200);
});


var offset = 0;
var endScroll = 0;
var lastType = '';
var ajaxOut = 0;
function get_newsfeed(type){
	if (ajaxOut == 0){
		ajaxOut = 1;
		
		if(type != lastType) {
			$('.newsfeed').html("<div class='loading' style='text-align:center;'>Loading . . . .</div>");
			endScroll = 0;
			offset = 0;
			lastType = type;
		}
		else if(endScroll == 0) {
			$('.newsfeed').append("<div class='loading' style='text-align:center;'>Loading . . . .</div>");
		}
		
		if (endScroll == 0){
			$.ajax({
				url: '/newsfeed',
				type: "post",
				data: {'lat': LATITUDE, 'lng': LONGITUDE, 'type' : type, 'offset' : offset},
				success: function(value) {
					ajaxOut = 0;
					$('.newsfeed .loading').remove();
					if (value.indexOf("endscroll") > -1){
						endScroll = 1;
						if (offset == 0){
							$('.newsfeed').append(value);
						}
					}
					else {
						$('.newsfeed').append(value);
					}
					offset += 20;
				}
			});
		}
		else {ajaxOut = 0;}
	}
}