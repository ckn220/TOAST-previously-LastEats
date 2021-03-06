
$(document).ready(function(){
	$('.guest_book textarea').live('keydown', function (e){
	    if(e.keyCode == 13){
	    	e.preventDefault();
	        add_comment($(this).parent().attr('num'));
	    }
	})
});

function add_comment(id){
	var comment = $('.guest_book[num='+ id +'] textarea').val();
	
	$.ajax({
		url: '/last_eat_entry/'+id,
		type: "post",
		data: {'comment': comment},
		success: function(value) {
			console.log(value);
			$('.guest_book[num='+ id +'] textarea').val('');
			$('.comments[num='+ id +']').append(value);
		}
	});
}

function delete_comment(thisObject, id){
	$.ajax({
		url: '/last_eat_entry/'+id,
		type: "delete",
		success: function(value) {
			$(thisObject).parent().remove();
		}
	});
}


ajaxOut = 0;
function saveIdea(thisObject, id){
	var items = $('.restaurant_photo_bottom[num='+ id +'] .saveicon').add('.icon_container[num='+ id +'] .saveicon');
	
	if (ajaxOut == 0){
		ajaxOut = 1;
		$.ajax({
			url: '/save_idea',
			type: "post",
			data: {'id': id},
			success: function(value) {
				console.log(value);
				ajaxOut = 0;
				if(value == 'ADDED'){
					items.removeClass('save');
					items.addClass('saved');
				}
				else{
					items.removeClass('saved');
					items.addClass('save');
				}
			}
		});
	}
}

function loveIdea(thisObject, id){
	var items = $('.restaurant_photo_bottom[num='+ id +'] .loveicon').add('.icon_container[num='+ id +'] .loveicon');
	
	if (ajaxOut == 0){
		ajaxOut = 1;
		$.ajax({
			url: '/love_idea',
			type: "post",
			data: {'id': id},
			success: function(value) {
				console.log(value);
				ajaxOut = 0;
				if(value == 'ADDED'){
					items.removeClass('love');
					items.addClass('loved');
					$('.restaurant_photo_bottom[num='+ id +'] .likeCount').html(parseInt($('.restaurant_photo_bottom[num='+ id +'] .likeCount').html()) + 1);
				}
				else {
					items.removeClass('loved');
					items.addClass('love');
					$('.restaurant_photo_bottom[num='+ id +'] .likeCount').html(parseInt($('.restaurant_photo_bottom[num='+ id +'] .likeCount').html()) - 1);
				}
			}
		});
	}
}

function removetag(thisObject, id, type, text){
	var url = '/removetag/'+ id +'/'+ type + '/' + text + '/';
	url = url.replace(' ', '%20');
	
	$.ajax({
		url: url,
		type: "DELETE",
		data: {},
		success: function(value) {
			$(thisObject).parent().remove();
		}
	});
}
