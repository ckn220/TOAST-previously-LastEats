//google maps
var geocoder;
var map;
var allMarkers = [];
var myMarker;
var infoWindow;

//google maps

function initialize() {
	geocoder = new google.maps.Geocoder();
	var latlng = new google.maps.LatLng(-5.397, 25.644);
	var mapOptions = {
		zoom: 2,
		center: latlng,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	}
	map = new google.maps.Map(document.getElementById('map_canvas'), mapOptions);
	
	// //New stuff
	// // Try HTML5 geolocation
	//   if(navigator.geolocation) {
	//     navigator.geolocation.getCurrentPosition(function(position) {
	//       var pos = new google.maps.LatLng(position.coords.latitude,
	//                                        position.coords.longitude);
	
	//       var infowindow = new google.maps.InfoWindow({
	//         map: map,
	//         position: pos,
	//         content: 'Location found using HTML5.'
	//       });
	
	//       map.setCenter(pos);
	//       // createMarker();
	//     }, function() {
	//       handleNoGeolocation(true);
	//     });
	//   } else {
	//     // Browser doesn't support Geolocation
	//     handleNoGeolocation(false); 
	//   }
	
	//with Jonas, geocoder changes for autocomplete 
	var input = document.getElementById('address');
	if(input){
		var autocomplete = new google.maps.places.Autocomplete(input);
		autocomplete.bindTo('bounds', map);
	}
	
	
	// load markers if available
	if (loadMarkers) {
		console.log("HERE!!!");
		loadMarkers();
	}
}

function handleNoGeolocation(errorFlag) {
	if (errorFlag) {
		var content = 'Error: The Geolocation service failed.';
	}
	else {
		var content = 'Error: Your browser doesn\'t support geolocation.';
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

setTimeout(function () {
	//$('.foo').addClass('bar');
	$('.foo').css({
		'height': 'auto'
	});
}, 1000);


