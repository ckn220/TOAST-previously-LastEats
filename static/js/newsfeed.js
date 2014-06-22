

$(document).ready(function(){
	$('body').scroll(function(){
		if ($('.ui-page').height() - ($('body').scrollTop() + $('body').height()) < 500){
			get_newsfeed(lastType);
		}
	)};
});


var offset = 0;
var endScroll = 0;
var lastType = '';
function get_newsfeed(type){
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
			url: 'newsfeed',
			type: "post",
			data: {'lat': LATITUDE, 'lng': LONGITUDE, 'type' : type, 'offset' : offset},
			success: function(value) {
				$('.newsfeed .loading').remove();
				$('.newsfeed').append(value);
				if (value == "\n"){
					endScroll = 1;
					if (offset == 0){
						$('.newsfeed').append("<div style='text-align:center;'>Woops nothing was found!</div>");
					}
				}
				offset += 20;
			}
		});
	}
}