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
			initialLocation = new google.maps.LatLng(position.coords.latitude,position.coords.longitude);
			
			LATITUDE = position.coords.latitude;
			LONGITUDE = position.coords.longitude;
			
			returnFunc();
			
		}, function() { handleNoGeolocation(browserSupportFlag, returnFunc); },
		{enableHighAccuracy: true});
	}
	// Browser doesn't support Geolocation
	else {
		browserSupportFlag = false;
		handleNoGeolocation(browserSupportFlag, returnFunc);
	}
}
function handleNoGeolocation(errorFlag, returnFunc) {
	if (errorFlag) {
		console.log('Error: The Geolocation service failed.');}
	else {
		console.log('Error: Your browser doesn\'t support geolocation.');}
		
	returnFunc();
}



//google maps

function initialize() {
	geocoder = new google.maps.Geocoder();
	
	if ($('.map_data.lat').length > 0){
		var map = $('#map_canvas').gmap({'disableDefaultUI':true, 'mapTypeId':google.maps.MapTypeId.ROADMAP, 'callback': function() {}});
		codeLatLng();
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
			alert('Geocode was not successful for the following reason: ' + status);
		}
	});
}

function codeLatLng() {
    var lat = parseFloat($('.map_data.lat').html());
	var lng = parseFloat($('.map_data.lng').html());
    var latlng = new google.maps.LatLng(lat, lng);
    geocoder.geocode({'latLng': latlng}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        if (results[1]) {
        	$('#map_canvas').gmap('get','map').setZoom(13);
        	$('#map_canvas').gmap('get','map').setCenter(latlng);
        	$('#map_canvas').gmap('addMarker', { 'position': latlng } ).click(function() {
                $('#map_canvas').gmap('openInfoWindow', {'content': '<a href="http://maps.google.com/maps?q='+results[0].formatted_address.replace('&','%26')+'" target="_blank">'+results[0].formatted_address+'</a>'}, this);
            });
      } else {
        alert("Geocoder failed due to: " + status);
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

function createMarker(lat,lng,titleText, bodyText, restaurant_name, restaurant_href) {
	console.log('createMarker');  
	// create google lat lng object
	var latLng = new google.maps.LatLng(String(lat), String(lng));
	console.log(latLng);
	
	var marker = new google.maps.Marker({
	position: latLng,
		map: map, 
		// title: titleText,
		// restaurant_name: restaurant_name,
		// bodyText: bodyText,
	});
	console.log("here");
	
	allMarkers.push(marker);
	console.log("also here");  
	
	google.maps.event.addListener(marker, 'click', function(event) {
		var latLng = event.latLng;
		restaurant_name = '<a href="/ideas/' + restaurant_href + '">' + restaurant_name || '' + '</a>';  //if body text is true run it, otherwise display string
		openInfoWindow(restaurant_name, latLng, map);
	});  
	
	return marker; 
	console.log("even here");
}

google.maps.event.addDomListener(window, 'load', initialize);

