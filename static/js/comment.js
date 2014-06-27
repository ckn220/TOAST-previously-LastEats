
$(document).ready(function(){
	$('.guest_book #textarea').live('keydown', function (e){
	    if(e.keyCode == 13){
	    	e.preventDefault();
	        add_comment($(this).parent().attr('num'));
	    }
	})
});

function add_comment(id){
	var comment = $('.guest_book[num='+ id +'] #textarea').val();
	
	$.ajax({
		url: 'last_eat_entry',
		type: "post",
		data: {'comment': comment,
				'id': id},
		success: function(value) {
			console.log(value);
			$('.guest_book[num='+ id +'] #textarea').val('');
			$('.comments[num='+ id +']').append(value);
		}
	});
}

function delete_comment(thisObject, id){
	$.ajax({
		url: 'last_eat_entry',
		type: "delete",
		data: {'id': id},
		success: function(value) {
			$(thisObject).parent().remove();
		}
	});
}


ajaxOut = 0;
function saveIdea(thisObject, id){
	if (ajaxOut == 0){
		ajaxOut = 1;
		$.ajax({
			url: 'save_idea',
			type: "post",
			data: {'id': id},
			success: function(value) {
				console.log(value);
				ajaxOut = 0;
				if(value == 'ADDED'){
					$(thisObject).removeClass('save');
					$(thisObject).addClass('saved');
				}
				else{
					$(thisObject).removeClass('saved');
					$(thisObject).addClass('save');
				}
			}
		});
	}
}

function loveIdea(thisObject, id){
	if (ajaxOut == 0){
		ajaxOut = 1;
		$.ajax({
			url: 'love_idea',
			type: "post",
			data: {'id': id},
			success: function(value) {
				console.log(value);
				ajaxOut = 0;
				if(value == 'ADDED'){
					$(thisObject).removeClass('love');
					$(thisObject).addClass('loved');
					$('.likeCount').html(parseInt($('.likeCount').html()) + 1);
				}
				else {
					$(thisObject).removeClass('loved');
					$(thisObject).addClass('love');
					$('.likeCount').html(parseInt($('.likeCount').html()) - 1);
				}
			}
		});
	}
}
