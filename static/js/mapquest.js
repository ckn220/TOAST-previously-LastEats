//google maps
var geocoder;
var map;
var allMarkers = [];
var myMarker;
var infoWindow;
var autocomplete = undefined;

//html5 geolocation
var LATITUDE = undefined;
var LONGITUDE = undefined;

function html5Geoloc(returnFunc){
	//Try W3C Geolocation (Preferred)
	if(navigator.geolocation) {
		browserSupportFlag = true;
		navigator.geolocation.getCurrentPosition(function(position) {
			LATITUDE = position.coords.latitude;
			LONGITUDE = position.coords.longitude;
			
			returnFunc();
			
		}, function (err) { 
			console.log('GEOLOCATION ERROR(' + err.code + '): ' + err.message);
			handleNoGeolocation(browserSupportFlag, returnFunc); 
		},
		{enableHighAccuracy: true, timeout:2000});
	}
	// Browser doesn't support Geolocation
	else {
		browserSupportFlag = false;
		handleNoGeolocation(browserSupportFlag, returnFunc);
	}
}
function handleNoGeolocation(errorFlag, returnFunc) {
	if (errorFlag) {
		console.log('Error: The Geolocation service failed.');
		
		$.ajax({
			url: 'http://freegeoip.net/json/',
			type: "get",
			success: function(value) {
				console.log(value);
				LATITUDE = value.latitude;
				LONGITUDE = value.longitude;
				
				returnFunc();
			},
			error: function(xhr, status, error) {
				console.log(xhr.responseText);
				returnFunc();
			}
		});
		}
	else {
		console.log('Error: Your browser doesn\'t support geolocation.');
		returnFunc();
	}
		
}



//google maps

function initialize() {
	html5Geoloc(function(){
		if ($('#multimap').length > 0){
			var map = $('#map_canvas').gmap({'disableDefaultUI':true, 'mapTypeId':google.maps.MapTypeId.ROADMAP, 'center':new google.maps.LatLng(LATITUDE, LONGITUDE),'callback': function() {}});
			codeLatLng(LATITUDE, LONGITUDE,{'url':'/static/img/bluedot.png','size': new google.maps.Size(20, 20),' anchor': new google.maps.Point(10, 10)},'Your Location');
			collectNearby(LATITUDE, LONGITUDE);
		}
	});
	
	geocoder = new google.maps.Geocoder();
	
	var map = $('#map_canvas').gmap({'disableDefaultUI':true, 'mapTypeId':google.maps.MapTypeId.ROADMAP, 'callback': function() {}});
	
	if ($('.map_data.lat').length > 0){
		codeLatLng(parseFloat($('.map_data.lat').html()), lng = parseFloat($('.map_data.lng').html()));
	}
	
	var input2 = document.getElementById('textinput-4');
	if (input2){
		var options = {
		  types: ['(cities)']
		};
		var autocomplete2 = new google.maps.places.Autocomplete(input2, options);
		google.maps.event.addListener(autocomplete2, 'place_changed', function () {
			var place = autocomplete2.getPlace();
			document.getElementById('cityLat').value = place.geometry.location.lat();
	        document.getElementById('cityLng').value = place.geometry.location.lng();
	        if (autocomplete){
		        var lati = place.geometry.location.lat();
		        var long = place.geometry.location.lng();
		        var s = new google.maps.LatLng(lati,long);
		        var n = new google.maps.LatLng(lati,long);
		        
		        var boundary = new google.maps.LatLngBounds(s,n);
		        autocomplete.setBounds(boundary);
	        }
	    });
	}
	
	var input = document.getElementById('address');
	if(input){
		autocomplete = new google.maps.places.Autocomplete(input);
		google.maps.event.addListener(autocomplete, 'place_changed', function () {
	        var place = autocomplete.getPlace();
	        document.getElementById('addressName').value = place.name;
	        document.getElementById('addressLat').value = place.geometry.location.lat();
	        document.getElementById('addressLng').value = place.geometry.location.lng();
	    });
	    if (req){
        	var s = new google.maps.LatLng(req.lati,req.long);
	        var n = new google.maps.LatLng(req.lati,req.long);
	        var boundary = new google.maps.LatLngBounds(s,n);
	        autocomplete.setBounds(boundary);
        }
		//autocomplete.bindTo('bounds', map);
	}
}
//End of new stuff

function codeAddress() {
	var address = document.getElementById('address').value;
	geocoder.geocode( { 'address': address}, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			// recenter map to new location
			map.setCenter(results[0].geometry.location);
			
			//var latLng = new google.maps.LatLng(results[0].geometry.location); 
			var location = results[0].geometry.location;
			
			createMarker(location.lat(), location.lng(),'some text');
			
			//WHY ISNT THIS GIVING ME THE FULL OBJECT? NOT JUST THE LAT/LNG
			console.log("results = " + results[0].geometry.location);
			
			// lat,lng,titleText, bodyText
			//console.dir(results[0].geometry);
			// console.log("new location at...");
			// console.log(results[0].geometry.location.lat());
			// console.log(results[0].geometry.location.lng());
			$("#longitude").val(results[0].geometry.location.lng());
			$("#latitude").val(results[0].geometry.location.lat());
		}
		else {
			console.log('Geocode was not successful for the following reason: ' + status);
		}
	});
}

function codeLatLng(lat, lng, icon, content) {
    var latlng = new google.maps.LatLng(lat, lng);
    
    var marker = { 'position': latlng, 'content': content}
    if (icon){
    	marker.icon = icon;
    }
    
    
    geocoder.geocode({'latLng': latlng}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        if (results[1]) {
        	if (marker.content){var content = marker.content;}
    	    else {var content = '<a href="http://maps.google.com/maps?q='+results[0].formatted_address.replace('&','%26')+'" target="_blank">'+results[0].formatted_address+'</a>';}
        	$('#map_canvas').gmap('get','map').setZoom(13);
        	$('#map_canvas').gmap('get','map').setCenter(latlng);
        	$('#map_canvas').gmap('addMarker', marker ).click(function() {
                $('#map_canvas').gmap('openInfoWindow', {'content': content}, this);
            });
      } else {
        console.log("Geocoder failed due to: " + status);
      }
    }});
}

function createInfoWindow(content, latLng){
	var infowindow = new google.maps.InfoWindow({
		position: latLng,
		content : content
	});
	return infowindow;
}

function openInfoWindow (content, latLng, map) {
	if(infoWindow){
		infoWindow.close();
		infoWindow = null;
	}
	infoWindow = createInfoWindow(content, latLng);
	infoWindow.open(map);
}

function createMarker(lat,lng, restaurant_name, restaurant_href, icon) {
	// create google lat lng object
	var latlng = new google.maps.LatLng(lat, lng);
	
	var marker = { 'position': latlng};
	if (icon){
		marker.icon = icon;
	}
	
	console.log('createMarker');
	$('#map_canvas').gmap('addMarker', marker ).click(function() {
        $('#map_canvas').gmap('openInfoWindow', {'content': '<a href="'+restaurant_href+'">'+restaurant_name+'</a>'}, this);
    });
}

google.maps.event.addDomListener(window, 'load', initialize);

