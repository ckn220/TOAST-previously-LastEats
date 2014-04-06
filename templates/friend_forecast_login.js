/*
NYU - ITP - MASHUPS CLASS
SPRING 2014
gihtub.com/craigprotzel/Mashups

FRIEND FORECASTER - EXAMPLE #2
References:
https://developers.facebook.com/
http://html5boilerplate.com/
http://underscorejs.org/
http://openweathermap.org/API#forecast
http://bugs.openweathermap.org/projects/api/wiki/Api_2_5_weather
http://openweathermap.org/wiki/API/Weather_Condition_Codes#Weather_Condition_Codes

*/

var FF = {};

//an object to store app config data.
FF.config = {}
FF.config.appId = '1393591570909609';
FF.config.debug = true;
FF.config.sampleSize = 50;

//arrays to store my friends and the cities.
FF.friends = [];
FF.cities = [];


//Add a method to the global app object that will authenticate Facebook.
FF.loadFriends = function(){
/* 
this is copy/paste from:
https://developers.facebook.com/docs/javascript/howto/jquery

scope defines what you can access from your account. You'll need to include everything you'll need to authorize
https://developers.facebook.com/docs/facebook-login/permissions#reference-extended-profile
*/
  $.ajaxSetup({ cache: true });
  $.getScript('//connect.facebook.net/en_UK/all.js', function(){
    FB.init({
      appId: FF.config.appId,
    });

  FB.login(function(){}, {scope: 'publish_actions,user_hometown,user_location,friends_location'});      
    FB.getLoginStatus(function (response) {
      if (response.authResponse) {
        //lets save the access token in our config object, in case we want to use it later.
        FF.config.accessToken = response.authResponse.accessToken;
        FB.api('/me', {accessToken: FF.config.accessToken, fields: 'hometown,location'}, function(response) {  
        console.log(response);
        FF.config.me = response;
        });
        FB.api('/me/friends', {accessToken: FF.config.accessToken, fields: 'name,location'}, function(response) {  
          var friends = response.data;
          var total = 0;
          var done = 0;
          var apiCalls = 0;
          var sample = (FF.config.debug) ? FF.config.sampleSize : friends.length;
          for (var i = 0; i < sample; i++) {
            if(typeof(friends[i].location) != 'undefined'){
              total += 1;

              $.ajax({
                  url: "http://api.openweathermap.org/data/2.5/forecast/daily?units=imperial&cnt=2&q=" + friends[i].location.name + '&' + i
                }).done(function(response) {
                    done +=1;
                   if(typeof(response.list) != 'undefined'){
                      i  = this.url.match(/\d+$/)[0];
                      friends[i].forecast = response.list;
                      console.log(response);

                      // add this new city to the colleciton of already-searched cities
                      FF.forecasts[friends[i].location.id] = response.list;
                      
                      //only keep the people that is not in my hometown, nor in my current city.
                      if (FF.config.me.hometown.id !== friends[i].location.id && FF.config.me.location.id !== friends[i].location.id ) {
                        FF.friends.push(friends[i]);
                        console.log(total + ' - ' + done );
                        $('#count').text(' ' + done + '/' + total + ' ' + 'friends.');
                      }

                    }
                    if(done >= total) { 
                      $('body').trigger('friendsLoaded'); 
                      $('#loading').text('Ready!');
                    }
                });

            } 
          }
        });
      } else {
        console.log('Facebook authorization failed!');
      }
  });
});
}



FF.groupFriendsByCity = function(){

  var grouped = _.groupBy(FF.friends, function(friend){ return friend.location.name; });
  _.each(grouped, function(data, key){
    var city = {};
    city.name = key;

    city.id = data[0].location.id;
    city.friends = data;
    city.friendsList =  _.map(data, function(friend, key){return friend.name; }).join(', ');
    city.forecast = data[0].forecast;
    city.tomorrow = {};
    // console.log(city.name);
    // console.log(data[0]);
    city.tomorrow.weather = data[0].forecast[1].weather[0].main;
    city.tomorrow.min = data[0].forecast[1].temp.min;
    city.tomorrow.max = data[0].forecast[1].temp.max;
    FF.cities.push(city);
  });
  
}



// Functions to generate the templates and display the views.

FF.listCities = function(){
  var list = $('#listTemplate').html();

  // console.log(FF.cities);
  var warmestToColdest = _.sortBy(FF.cities, function(city){ return -city.tomorrow.max; });
  $('#list').html(_.template(list, {cities: warmestToColdest}));

  var ideal =  _.find(warmestToColdest, function(city){ return city.tomorrow.max < 80});
  console.log(ideal);
  $('html, body').animate({
    scrollTop: $('#'+ideal.id).offset().top - 200
    }, 1000);
  $('tr').on('click', function(){
    var id = $(this).attr('id');
    FF.cityDetail(id);

  });
}

FF.cityDetail = function(id){
  $('html, body').animate({
    scrollTop: 0
    }, 500);
  console.log('rendering city detail');
  var detail = $('#detailTemplate').html();
  var city = _.find(FF.cities, function(city){ return city.id == id});
  console.log(city);
  $('#detail').html(_.template(detail, {city: city})).show();
  $('#list').hide();
}



// lets initialize this thing.

$(document).ready(function() {

  FF.loadFriends();

  // when data has finished loading, display in screen.
  $('body').on({
    'friendsLoaded' : function(){
      $('#loading').fadeOut();
      FF.groupFriendsByCity();
      FF.listCities();
    }
  });


  // navigation handlers
  $('h1').on({ 
    'click' : function(){
      $('#detail').hide();      
      $('#list').show();      
    }
    
})






});









// function getUserFriends() {  
//     FB.api('/me/friends?fields=name,picture', function(response) {  
//         console.log('Got friends: ', response);  
  
//         if (!response.error) {  
//             $('#categorieslist').empty();  
//             var markup = '';  
  
//             var friends = response.data;  
  
//             for (var i = 0; i < friends.length && i < 25; i++) {  
//                 var friend = friends[i];  
  
//                 markup += '  
// <li><img src="%27%20+%20friend.picture%20+%20%27"> ' + friend.name + '</li>  
// ';  
//             }  
//             $("#categorieslist").html(markup);  
//             $("#categorieslist").listview("refresh");  
//             //document.getElementById('user-friends').innerHTML = markup;  
//         }  
//     });  
// }  