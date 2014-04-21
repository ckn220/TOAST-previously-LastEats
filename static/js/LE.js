//fb api work for login

var LE = {
	facebook : {
		friends: [],

		init: function(){
			var deferred = $.Deferred();
        		
    		LE.facebook.getFriends().done(function(friends){
				LE.facebook.friends = friends;
				deferred.resolve();
			});
        	
        	return deferred.promise();
		},

		getFriends: function(){
		 	var deferred = $.Deferred();			

            FB.api('/me/friends', function(response){
            	//whats in here is being sent to the call back within done
            	deferred.resolve(response.data);

            });

            return deferred.promise();
		},

		getFriendsOnLastEats: function(allFriends){
            var deferred = $.Deferred();

            var lastEaters = [];
                FB.api({
                		method: 'fql.query',
                  		query: 'SELECT uid FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) AND is_app_user = 1'
                	},
                	function(friends) {
                		var friendsWithNames = [];

                   		_.each(friends, function(friend){
                   			var friendWithName = LE.facebook.getFriend(friend.uid);
							friendsWithNames.push(friendWithName);
                   		});

                   		deferred.resolve(friendsWithNames);
	                }
           	 	);

           	return deferred.promise();
        },

        getFriend: function(id){
        	var _friend;

    		_.each(LE.facebook.friends, function(friend){
    			//console.log(id, friend.id, (id == friend.id));
    			if(friend.id == id)
    				_friend = friend;
    		});	

    		return _friend;
        },

        getPhoto: function(id){
        	//get this phot and push into the freinds array 
        	//get photo from facebook api
        	//run thorugh LE.facebook.friends and insert photo where is matches
        	// LE.facebook.friends = friends;

        	FB.api('/me/friends?fields=name,picture', function(response) {  
		        	console.log('Got friends: ', response);  
		  
		        if (!response.error) {  
		            $('#categorieslist').empty();  
		            var markup = '';  
		  
		            var friends = response.data;  
		  
		            for (var i = 0; i < friends.length; i++) {  
		                var friend = friends[i];  
		  
		                markup += ' <li><img src="%27%20+%20friend.picture%20+%20%27"> ' + friend.name + '</li>  ';  
		            }  
		            $("#categorieslist").html(markup);  
		            $("#categorieslist").listview("refresh");  
		            //document.getElementById('user-friends').innerHTML = markup;  
		        }  
		    });  
		}  


        }
	}
