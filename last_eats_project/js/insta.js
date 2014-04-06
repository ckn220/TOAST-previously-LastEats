// This is the insta.js taken for reference from worldc.am site 




(function(window, $, undefined) {
	var app = window.Insta || (window.Insta = {});
	var $window = $(window);

	var location = null;
	var position = null;
	var latestField = 0;
	var originalposition = null;
	var trendingResults = [];
	var locationResults;
	var feedItems;
	var savedLocations = {};
	var savedPositions = {};
	var isPushing = false;
	var isAbout = false;
	var isVisible = false;
	var isIE = 0;
	var backObjects = [];
	var map;
	var mapMarker = "OSKAR";
	var geocoder;

	var autorun = function() {
		if (!window.console) window.console = {};
		if (!window.console.log) window.console.log = function () { };
		//sconsole.log("autorun()");
		//alert("yo");
		isIE = (function(){
			var undef,
			v = 3,
			div = document.createElement('div'),
			all = div.getElementsByTagName('i');

			while (
				div.innerHTML = '<!--[if gt IE ' + (++v) + ']><i></i><![endif]-->',
				all[0]
			);

			return v > 4 ? v : undef;

		}());
		//alert("isIE: " + isIE);
		// getIPGeo();
		//getBrowserGeo();
		fixConsole();
		if (isIE < 9) {
			doIE();
		} else {
			if (isIE) {
				showError("We currently have issues with Internet Explorer.");
			}
			startComplete();
		}
	};

	var doIE = function() {
		//console.log("isIE()");
		$("#homelink").bind('click', {}, onHome);
		$("#aboutlink").bind('click', {}, onAbout);
		$("header").css("height", "500px");
		var ieMess = $("<p class='headerbig'>We're very sorry about this, but Worldcam<br>does not work on your current web browser.<br><br>For a better web experience, please upgrade.</p>");
		ieMess.css("top", "140px");
		$("header").append(ieMess);
	};

	var getBrowserGeo = function(callbacker) {
		console.log("onBrowserGeo()");
		if ("geolocation" in navigator) {
			/* geolocation is available */
			if (navigator.geolocation) {
				console.log("navigator.geolocation fanns3");
				var geoTimeOut = setTimeout(function() {
					getIPGeo(callbacker);
				}, 10000);
				navigator.geolocation.getCurrentPosition(function(geoPosition) {
					clearTimeout(geoTimeOut);
					console.log("getBrowserGeo done");
					console.log(geoPosition);
					//do_something(position.coords.latitude, position.coords.longitude);
					getPositionFullFromLongLat(geoPosition.coords.longitude, geoPosition.coords.latitude, function() {
						console.log("inside callbacker.");
						originalposition = position;
						savedPositions[encodePositionURL(position.city, position.cc)] = {position:position};
						callbacker(true);
					});
				}, function() {
					clearTimeout(geoTimeOut);
					console.log("du ville inte.");
					getIPGeo(callbacker);
				});
			} else {
				console.log("1");
				getIPGeo(callbacker);
			}
		} else {
			console.log("2");
			getIPGeo(callbacker);
		}
	};

	var getIPGeo = function(callbacker) {
		$.ajax({
			url: "http://www.geoplugin.net/json.gp?jsoncallback=?",
			crossDomain: true,
			dataType: "jsonp",
			data: {},
			success: function(data) {
				console.log("inne");
				console.log(data);
				if (data) {
					originalposition = position = {
						longitude: data.geoplugin_longitude,
						latitude: data.geoplugin_latitude,
						city: data.geoplugin_city,
						country: data.geoplugin_countryName,
						cc: data.geoplugin_countryCode,
					region: data.geoplugin_regionName
					};
					savedPositions[encodePositionURL(position.city, position.cc)] = {position:position};
					callbacker(true);
				} else {
					console.log("nu är det fel.");
					showError("We're experiencing geolocation issues.");
					callbacker(false);
				}
				//geoComplete(data.geoplugin_city + ", " + data.geoplugin_countryName, data.geoplugin_longitude, data.geoplugin_latitude);
			},
			error: function(jqXHR, textStatus, errorThrown) {
				callbacker(false);
			}
		});
	};

	var startComplete = function() {
		console.log("startComplete()");
		setupPage();
		startHistory();

		console.log("STÖD: " + Path.history.supported);

		if (Path.history.supported) {
			Path.history.popState();
		} else {
			startIE();
			//Path.history.popState();
		}
	};

	var startIE = function() {
		var url = window.location.href;
		console.log("URL: " + url);
		var a = document.createElement('a');
		a.href = url;
		var path = a.pathname + a.search;
		var paths = path.split("/");
		console.log(paths);
		//alert(paths);
		if (paths.length > 1) {
			console.log("inne här...");
			console.log(path);
			setTimeout(function() {
				path = "/" + path;
				//alert("'" + path + "'");
				Path.history.pushState({}, "Worldcam - Search Instagram by location", path);
			}, 500);
		}
	};

	var hideBack = function() {
		//$("#back-container").animate({ opacity: 0 }, 200);
	};

	var startHistory = function() {
		Path.map("/id/:id").to(function() {
			console.log("0");
			if (!isPushing) {
				var id = this.params.id;
				loadFromFoursquare(id);
			} else {
				console.log("CAUGHT THIS!");
			}
		});

		Path.map("/ls/:id/:ps").to(function() {
			console.log("1");
			var loca = decodeURIComponent(this.params.id);
			var posa = this.params.ps;
			onSearchLocation(loca, posa);
			updateAnalytics();
		});

		Path.map("/ps/:id").to(function() {
			console.log("2");
			var posi = decodeURIComponent(this.params.id);
			onSearchPosition(posi);
			updateAnalytics();
		});

		Path.map("/p/:id").to(function() {
			console.log("3");
			var posi = this.params.id;
			setPositionFromID(posi);
			updateAnalytics();
		});

		Path.map("/").to(function(){
			console.log("4");
			setOriginalPosition();
			updateAnalytics();
			//showError("We might hit Instagram rate limits, but if the site doesn't work, just come back later!");
		});

		Path.root("/");

		console.log("Path innehåller:");
		console.log(Path);

		Path.history.listen(true);


	};

	var clearPage = function() {
		console.log("clearPage()");
		hideLocationInfo();
		hideSearch();
		clearLocation();
		location = null;
		//position = originalposition;
	};

	var setFormFields = function() {
		console.log("setFormFields()");
		setLocationField();
		setPositionField();
	};

	var setLocationField = function() {
		if (location) {
			//$("#formlocation").val(getLocationString(location));
			$("#formlocation").val(location.name);
		}
	};

	var setPositionField = function() {
		console.log("setPositionField()");
		// console.log(position);
		// console.log(trendingResults);
		// console.log(trendingResults.length);
		if (position) {
			$("#formposition").val(getPositionString());
			var numTrending = Math.min(6, trendingResults.length);
			if (trendingResults.length > 0) {
				var results = "Enter any venue in <span class='bubblename'>" + getPositionString() + "</span><p class='bubbletrend'>Popular here right now: ";
				for (var i = 0; i < numTrending; i++) {
					results += '<span id="trend' + i + '" class="whitelink">' + trendingResults[i].name + '</span>';
					if (i < (numTrending - 1)) {
						results += ", ";
					}
				}
				results += ".</p>";
				$("#bubblelocationcontent").html(results);
				for (i = 0; i < numTrending; i++) {
					(function(loc) {
						$("#trend" + i).bind('click', {}, function() {
							loadFromFoursquareExisting(loc.id, loc.categories, loc.location, loc.name);
						});
					})(trendingResults[i]);
				}
			} else {
				$("#bubblelocationcontent").html("Enter any venue in<span class='bubblename'> " + getPositionString() + "</span><p class='bubbletrend'>For example a restaurant, bar, park, building etc.</p>");
			}
		}
	};

	var showStart = function() {
		if (!isVisible) {
			isVisible = true;
			$('#form').css('visibility', 'visible');

		}
	}

	var setBubbles = function(forceBubble) {
		console.log("setBubbles(" + forceBubble+")");
		var bubble = forceBubble || 0;
		if (bubble === 0) {
			if (position) {
				bubble = 1;
			} else {
				bubble = 2;
			}
		}
		//console.log("OCH BUBBLE: " + bubble);
		if (bubble === 1) {
			$('#bubblelocation').css('visibility', 'visible');
			$('#bubbleposition').css('visibility', 'hidden');
		} else if (bubble === 2) {
			$('#bubblelocation').css('visibility', 'hidden');
			$('#bubbleposition').css('visibility', 'visible');
		}
	};

	var hideBubble = function() {
		$('#bubblelocation').css('visibility', 'hidden');
		$('#bubbleposition').css('visibility', 'hidden');
	};

	var setupPage = function() {
		console.log("setupPage()");

		if (isIE != 19) {
			$("#formlocation").marcoPolo({
				// url: "https://api.foursquare.com/v2/venues/suggestcompletion",
				url: "https://api.foursquare.com/v2/venues/search",
				formatData: function (data) {
					console.log("formLocation data:");
					console.log(data);
					//return data.response.minivenues;
					if (data.response.venues.length > 0) {
						return data.response.venues;
					} else {
						return null;
					}
				},
				formatItem: function (data, $item) {
					console.log("ITEM:");
					console.log(data);
					var imgTag;
					if(data.categories.length) {
						catName = "(" + data.categories[0].name+ ")";
						locImage = "<img class='locimage' width='24' height='24' src='" + data.categories[0].icon.prefix + "32" + data.categories[0].icon.name + "'>";
					} else {
						catName = "";
						locImage = "<img class='locimage' width='24' height='24' src='/images/backup_32.png'>";
					}
					return "<div class='locdrops'>" + locImage + "<div class='loctext'>" + getLocationString(data) + "</div></div>";
				},
				minChars: 3,
				onSelect: function (data, $item) {
					console.log("**! Selected item:");
					console.log(data);

					setTimeout(function() {
						$("#formlocation").blur();
						setFormFields();
					}, 10);

					loadFromFoursquareExisting(data.id, data.categories, data.location, data.name);
				},
				onFocus: function() {
					console.log("location.onFocus()");
					$("#formlocation").val("");
				},
				onBlur: function() {
					console.log("location.onBlur()");
					latestField = 1;
					if ($("#formlocation").val() === "") {
						setLocationField();
					}
				},
				param: 'query',
				required: false
	        });

	        //setLocationData();

			$("#formposition").marcoPolo({
				url: "http://api.geonames.org/searchJSON",
				data: {
					maxRows: '8',
					featureClass: "P",
					style: "full",
					username: "gori"
				},
				formatData: function (data) {
					if (position) {
						position.autocomplete = data.geonames;
					}
					if (data.geonames.length > 0) {
						return data.geonames;
					} else {
						return null;
					}


				},
				formatItem: function (data, $item) {
					if (data.adminName1.length > 1) {
						return data.name + ", " + data.adminName1 + ", " + data.countryName;
					} else {
						return data.name + ", " + data.countryName;
					}
				},
				minChars: 3,
				onSelect: function (data, $item) {
					console.log("*!* Selected item:");
					console.log(data);
					if (typeof(data) == "object") {
						setPosition(data.lng, data.lat, data.name, data.adminName1, data.countryName, data.countryCode);

					} else {
						console.log("--- NEJ här fångar vi en felaktig onSelect!");
					}
				},
				onFocus: function() {
					console.log("position.onFocus()");
					$("#formposition").val("");
					setBubbles(2);
				},
				onBlur: function() {
					console.log("position.onBlur()");
					latestField = 2;
					if ($("#formposition").val() === "") {
						setPositionField();
					}
					setBubbles();
				},
				param: 'name_startsWith',
				required: false
	        });
		}
		var mailerLink = 'To contact us, please send us an <a href="ma';
		mailerLink += 'ilto:b';
		mailerLink += 'ig@';
		mailerLink += 'kindalikeabigdeal.';
		mailerLink += 'com">emai';
		mailerLink += 'l</a> or say hi on twitter (<a href="http://twitter.com/theworldcam" target="_blank">@theworldcam</a>).';
		$("#maillink").html(mailerLink);

		console.log("----------------------------------");
		$('#formob').on('submit', function( e ) {
			e.preventDefault();
			return false
		});
		$("#backlink").bind('click', {}, hideAbout);
		$("#homelink").bind('click', {}, onHome);
		$("#topmenulogo").bind('click', {}, onHome);
		$("#aboutlink").bind('click', {}, onAbout);
		$("#formsubmit").bind('click', {}, onSearch);
		$("#feedmore").bind('click', {}, loadMoreLocation);
		$('#faceshare').bind('click', {site:"facebook"}, sharePage);
		$('#twittershare').bind('click', {site:"twitter"}, sharePage);
		$('#twittershare').bind('click', {site:"twitter"}, sharePage);

		mapMarker = initMap();
	};

	var setLocationData = function() {
		console.log("setLocationData");
		console.log(position);
		if (position) {
			var data = {
				ll: position.latitude + "," + position.longitude,
				v: "20120214",
				limit: 8,
				llAcc: 1000,
				client_id: "I4M3IJICBQCQV55JFHANTW1BLBQ1QKHSQI1JL34KDKTKTN3H",
				client_secret: "GB5TJFDRAF3FRJBSN2JAPMC3SUWW4YKAOK1HLEZ2ZOCEYEY2"
			};
			$('#formlocation').marcoPolo('option', 'data', data);
		}
	};

	var setPosition = function(datalng, datalat, dataname, dataadmin, datacountry, dataCC) {
		var posURL;
		console.log("setPosition() " + posURL);
		location = {};
		if (datalng) {
			posURL = encodePositionURL(dataname, dataCC);
			savedPositions[posURL] = {
				position:{
					longitude: datalng,
					latitude: datalat,
					city: dataname,
					region: dataadmin,
					country: datacountry,
					cc: dataCC
				}
			};
		} else {
			posURL = encodePositionURL(position.city, position.cc);
			savedPositions[posURL] = {
				position:position
			};
		}

		Path.history.pushState({}, "Worldcam - Search " + posURL.split(",")[0] + " by location.", "/p/" + posURL);
	};

	var savePosition = function() {
		savedPositions[encodePositionURL(position.city, position.cc)] = {
			position:position
		};
	};

	var setOriginalPosition = function() {
		console.log("setOriginalPosition()");
		if (originalposition) {
			position = originalposition;
			trendingResults = [];
			startPromoted();
			setLocationData();
			clearPage();
			setFormFields();
			setBubbles();
			showStart();

			if (position) {
				loadTrending();
				$("#formlocation").focus();
			}
		} else {
			console.log("INGEN originalposition");
			getBrowserGeo(function(isSuccess) {
				showStart();
				console.log("SUCCESS: " + isSuccess);
				if (isSuccess) {
					console.log("position got");
					trendingResults = [];
					startPromoted();
					setLocationData();
					clearPage();
					setFormFields();
					setBubbles();
					$("#formlocation").focus();
					loadTrending();
				} else {
					trendingResults = [];
					setLocationData();
					clearPage();
					setFormFields();
					setBubbles();
				}
			});
		}
	};

	var setPositionFromID = function(posURL) {
		console.log("setPositionFromID() " + posURL);
		trendingResults = [];
		setFormFields();
		showStart();
		if (savedPositions[posURL]) {
			console.log("Position fanns buffrad.");
			position = savedPositions[posURL].position;
			endPosition();

		} else {
			console.log("Position fanns INTE buffrad.");
			loadPositionFromID(posURL);
		}
	};

	var loadPositionFromID = function(posURL, callback) {
		console.log("loadPositionFromID(" + posURL + ")");
		var positions = decodePositionURL(posURL);
		var searchURL = "http://api.geonames.org/searchJSON";
		console.log(positions[0]);
		console.log(positions[1]);
		$.ajax({
			type: "GET",
			dataType: "jsonp",
			cache: false,
			url: searchURL,
			data: {
				name: positions[0],
				country: positions[1],
				maxRows: '2',
				featureClass: "P",
				style: "full",
				username: "gori"
			},
			success: function(data) {
				console.log("loadPositionFromID success");
				console.log(data);
				if (data.geonames.length > 0) {
					position = {
						longitude: data.geonames[0].lng,
						latitude: data.geonames[0].lat,
						city: data.geonames[0].name,
						region: data.geonames[0].adminName1,
						country: data.geonames[0].countryName,
						cc: data.geonames[0].countryCode
					};
					if (callback) {
						callback();
					} else {
						endPosition();
					}
				} else {
					console.log("********************** STORBUGG!");
				}
			},
			error: function(jqXHR, textStatus, errorThrown) {
				showError("ERROR loadPositionFromID: " + textStatus);
			}
		});
	};

	var endPosition = function() {
		setLocationData();
		setFormFields();
		hideSearch();
		hideLocationInfo();
		clearLocation();
		loadTrending();
		setBubbles();
		setTimeout(function() {
			$("#formlocation").focus();
		}, 100);
	};

	var initMap = function() {
		var mapOptions = {
			zoom: 13,
			center: new google.maps.LatLng(-33.9, 151.2),
			// disableDefaultUI: true,
			draggable: true,
			scrollwheel: false,
			streetViewControl: false,
			mapTypeControl: false,
			mapTypeId: google.maps.MapTypeId.ROADMAP
		}
		map = new google.maps.Map(document.getElementById('locationmap'), mapOptions);

		var image = '/images/mapmarker.png';
        var myLatLng = new google.maps.LatLng(-33.9, 151.2),
        mapMarker = new google.maps.Marker({
            position: myLatLng,
            map: map,
            icon: image
        });
        return mapMarker;
	};

	var moveMap = function() {
		var pos = new google.maps.LatLng(location.location.lat, location.location.lng);
		google.maps.event.trigger(map, 'resize');
		map.setCenter(pos);
		mapMarker.setPosition(pos);

	};

	var loadTrending = function() {
		console.log("loadTrending()");
		console.log(position.latitude + ", " + position.longitude);

		trendingResults = [];

		var searchURL = "https://api.foursquare.com/v2/venues/trending";

		$.ajax({
			type: "GET",
			dataType: "jsonp",
			cache: false,
			url: searchURL,
			data: {
				ll: position.latitude + "," + position.longitude,
				v: "20120214",
				limit: 40,
				radius: 10000,
				client_id: "I4M3IJICBQCQV55JFHANTW1BLBQ1QKHSQI1JL34KDKTKTN3H",
				client_secret: "GB5TJFDRAF3FRJBSN2JAPMC3SUWW4YKAOK1HLEZ2ZOCEYEY2"
			},
			success: function(data) {
				console.log("loadTrending succeded");
				console.log(data);
				if (data.response.venues) {
					if (data.response.venues.length > 0) {
						// $("#trending").css("display", "block");
						trendingResults = data.response.venues;
						setPositionField();
					} else {
						trendingResults = [];
					}
				}
			},
			error: function(jqXHR, textStatus, errorThrown) {
				showError("ERROR loadTrending: " + textStatus);
			}
		});
	};

	var onSearch = function(event) {
		console.log("onSearch()");
		event.preventDefault();
		hideSearch();

		console.log("Okej nu visar vi: " + isLocationField() + " / " + isPositionField());

		if (isLocationField() && isPositionField()) {
			console.log("SORRY INGET SÖK.");
		} else if ((!isLocationField() && isPositionField()) || (!isLocationField() && latestField == 1) && $("#formlocation").val() !== "") {
			console.log("Location Sök");
			Path.history.pushState({}, "Worldcam - Search Instagram by location", "/ls/" + encodeURIComponent($("#formlocation").val()) + "/" + encodePositionURL(position.city, position.cc));
		} else if ((isLocationField() && !isPositionField()) || (!isPositionField() && latestField == 2) && $("#formposition").val() !== "") {
			console.log("Position Sök");
			Path.history.pushState({}, "Worldcam - Search Instagram by location", "/ps/" + encodeURIComponent($("#formposition").val()));
		}
		return false;
	};

	var onSearchLocation = function(searchString, positionString) {
		showLoader();
		clearLocation();
		hideLocationInfo();
		hideError();

		if (savedPositions[positionString]) {
			console.log("*** Fanns sparad.");
			position = savedPositions[positionString].position;
			searchLocation(searchString);
		} else {
			console.log("*** Fanns inte sparad.");
			console.log(savedPositions);
			loadPositionFromID(positionString, function() {
				searchLocation(searchString);
			});
		}
	};

	var searchLocation = function(searchString) {
		var searchURL = "https://api.foursquare.com/v2/venues/search";
		$("#formlocation").val(searchString);
		location = {};
		setPositionField();

		$.ajax({
			type: "GET",
			dataType: "jsonp",
			cache: false,
			url: searchURL,
			data: {
				ll: position.latitude + "," + position.longitude,
				v: "20120214",
				limit: 30,
				client_id: "I4M3IJICBQCQV55JFHANTW1BLBQ1QKHSQI1JL34KDKTKTN3H",
				client_secret: "GB5TJFDRAF3FRJBSN2JAPMC3SUWW4YKAOK1HLEZ2ZOCEYEY2",
				query: searchString
			},
			success: function(data) {
				onSearchLocationComplete(data);
			},
			error: function(jqXHR, textStatus, errorThrown) {
				showError("ERROR searchLocation: " + textStatus);
			}
		});
	};

	var onSearchLocationComplete = function(data) {
		console.log("onSearchLocationComplete()");
		console.log(data);

		setBubbles();
		hideLoader();
		showStart();

		var venues = data.response.venues;
		var results;
		showLocationSearch();

		if (venues.length === 0) {
			results = "<ol class='searchlist'><li class='searchitem'><span class='searchname'>Sorry, no results found.</span>";
			results += "<p class='searchaddress'>Try searching again.</p></li></ol>";
			$("#searchlocation").html(results);
		} else {
			locationResults = venues;
			var catName;
			var locImage;
			results = "<ol class='searchlist'>";
			for (var i = 0; i < venues.length; i++) {
				if(venues[i].categories.length) {
					catName = "(" + venues[i].categories[0].name+ ")";
					locImage = "<img class='searchimage' width='24' height='24' src='" + venues[i].categories[0].icon.prefix + "32" + venues[i].categories[0].icon.name + "'>";
				} else {
					catName = "";
					locImage = "<img class='searchimage' width='24' height='24' src='/images/backup_32.png'>";
				}
				results += "<li class='searchitem searchlink' id='searchitem" + i + "''>" + locImage + "<span class='searchname'>" + getLocationString(venues[i]) + " <span class='searchcategory'>" + catName + "</span></span>";
				if (venues[i].location.address) {
					results += "<p class='searchaddress'>" + (venues[i].location.address || "") + ', ' + (venues[i].location.postalCode || "") + ' ' + (venues[i].location.city || "") + ', ' + (venues[i].location.state || "") + '</p>';
				}
			}	results += "</li>";
			results += "</ol>";
			$("#searchlocation").html(results);
			for (i = 0; i < venues.length; i++) {
				(function(i, loc) {
       				$("#searchitem" + i).bind('click', {item:i, loc:loc}, onSearchLocationClick);
				})(i, venues[i]);
			}
		}
	};

	var onSearchPosition = function(searchString) {
		console.log("onSearchPosition()");
		location = {};
		showLoader();
		clearLocation();
		hideLocationInfo();
		hideError();

		var searchURL = "http://api.geonames.org/searchJSON";
		$("#formposition").val(searchString);

		$.ajax({
			type: "GET",
			dataType: "jsonp",
			cache: false,
			url: searchURL,
			data: {
				name_startsWith: searchString,
				maxRows: '30',
				featureClass: "P",
				style: "full",
				username: "gori"
			},
			success: function(data) {
				onSearchPositionComplete(data);
			},
			error: function(jqXHR, textStatus, errorThrown) {
				showError("ERROR onSearchPosition: " + textStatus);
			}
		});
	};

	var onSearchPositionComplete = function(data) {
		console.log("onSearchPositionComplete()");
		console.log(data);

		hideLoader();

		var positions = data.geonames;
		console.log("Antal svar: " + positions.length);
		var results;
		showPositionSearch();
		showStart();

		if (positions.length === 0) {
			//showError("No results found, but please try searching again.");
			results = "<ol class='searchlist'><li class='searchitem'><span class='searchname'>Sorry, no results found.</span>";
			results += "<p class='searchaddress'>Try searching again.</p></li></ol>";
			$("#searchposition").html(results);

		} else {
			results = "<ol class='searchlist'>";
			for (var i = 0; i < positions.length; i++) {
				results += "<li class='searchitem searchlink' id='searchpositem" + i + "''><span class='searchname'>" + positions[i].name + "</span>";
				results += "<p class='searchaddress'>" + (positions[i].adminName1 || "") + ', ' + (positions[i].countryName || "") + '.</p>';
			}	results += "</li>";
			results += "</ol>";
			$("#searchposition").html(results);
			for (i = 0; i < positions.length; i++) {
				(function(pos) {
       				$("#searchpositem" + i).bind('click', {data:pos}, onSearchPositionClick);
				})(positions[i]);
			}
		}
	};

	var onSearchLocationClick = function(data) {
		var item = data.data.item;
		var loc = data.data.loc;
		console.log("onSearchClick(" + item + ")");
		console.log(loc);

		loadFromFoursquareExisting(loc.id, loc.categories, loc.location, loc.name);
	};

	var onSearchPositionClick = function(data) {
		data = data.data.data;
		console.log("onSearchPositionClick()");
		console.log(data);
		setPosition(data.lng, data.lat, data.name, data.adminName1, data.countryName, data.countryCode);
	};

	var startLoad = function() {
		console.log("*** startLoad() ***");

		hidePromoted();
		showLoader();
		hideSearch();
		clearLocation();
		hideLocationInfo();
		hideError();
		disableForm();
		hideBubble();

		$(this).scrollTop(0);
		$("#feedlist").html("");
		$("#feedmore").css("display", "none");
		$("#feednone").css("display", "none");
	};

	var endLoadOne = function() {
		console.log("*** endLoadOne() ***");
		showLocationInfo();
		enableForm();
		setFormFields();
		loadTrending();
		setBubbles();
		showStart();

		console.log("OCH DEN SLUTAR PÅ: " + position.city + ", " + position.country);
		console.log("OCH: " + position.longitude + ", " + position.latitude);
	};

	var startLoadMore = function() {
		showLoader();

		$("#feedmore").css("display", "none");
	};

	var endLoadFiles = function() {
		hideLoader();

		if (location.pagination.next_max_id) {
			$("#feedmore").css("display", "block");
		} else {
			$("#feedmore").css("display", "none");
		}
	};

	var endLoadNoFiles = function(isError) {
		console.log("endLoadNoFiles(" + isError + ")");
		// isError ska vara om den inte lyckades converta location... om vi nu vill visa det?
		//showError("ERROR: Couldn't convert location.");
		//$("#feedresults").html('<p id="geoload" class="textlink">Click here to load by map position instead.</p>');
		//$("#geoload").bind('click', {}, loadGeoLocation);

		if (isError) {
			// DREAD
			//showError("ERROR: Couldn't convert location.");
			$("#feed").css("display", "block");
			$("#feednone").css("display", "block");
		} else {
			// ID: 4d0be34b3d63f04dc4471f53
			$("#feed").css("display", "block");
			$("#feednone").css("display", "block");
		}

		hideLoader();
	};

	var loadFromFoursquare = function(id) {
		startLoad();

		if (savedLocations[id]) {
			console.log("HITTAD I BUFFERN!!!!");

			position = savedLocations[id].position;
			location = savedLocations[id].location;
			location.pagination = null;
			setLocationData();
			endLoadOne();
			loadImages();

		} else {
			console.log("!!!!!!! ALLTSÅ HÄR ÄR RIKTIGA !!!!!!!");
			trendingResults = [];
			searchURL = "/venuebuffer.php?id=" + id;
			console.log(searchURL);
			$.ajax({
				type: "GET",
				dataType: "json",
				cache: false,
				data: {id:id},
				contentType: "application/json; charset=utf-8",
				url: searchURL,
				success: function(data) {
					console.log("loadFromFoursquare succeded");
					console.log(data);
					if (data) {
						location = {
							categories: data.response.venue.categories,
							id: data.response.venue.id,
							location: data.response.venue.location,
							name: data.response.venue.name,
							images: []
						};

						position = {
							longitude: data.response.venue.location.lng,
							latitude: data.response.venue.location.lat,
							city: data.response.venue.location.city,
							country: data.response.venue.location.country,
							cc: data.response.venue.location.cc
						};

						savePosition();

						if (position.city) {
							console.log("hittade position.city");
							setLocationData();
							loadFromFoursquareConvert();
						} else {
							console.log("!!!!!!!!!!! HITTADE INTE!!!!!!!!!!!!");
							getPositionFullFromLongLat(position.longitude, position.latitude, function() {
								console.log("callback...");
								endLoadOne();
								loadFromFoursquareConvert();
							});
							//getPositionName();
						}
					} else {
						console.log("Caught error.");
						showError("ERROR: Location not found.");
						enableForm();
						onHome();
						//endLoadOne();
					}
				},
				error: function(jqXHR, textStatus, errorThrown) {
					showError("ERROR: Location not found." + textStatus);
					console.log("!!!!!!!!! error");
					console.log(jqXHR);
					console.log(textStatus);
					console.log(errorThrown);
					onHome();
				}
			});
			//var searchURL = "https://api.foursquare.com/v2/venues/" + id;
			// $.ajax({
			// 	type: "GET",
			// 	dataType: "jsonp",
			// 	cache: false,
			// 	url: searchURL,
			// 	data: {
			// 		v: "20120214",
			// 		client_id: "I4M3IJICBQCQV55JFHANTW1BLBQ1QKHSQI1JL34KDKTKTN3H",
			// 		client_secret: "GB5TJFDRAF3FRJBSN2JAPMC3SUWW4YKAOK1HLEZ2ZOCEYEY2"
			// 	},
			// 	success: function(data) {
			// 		console.log("loadFromFoursquare succeded");
			// 		console.log(data);
			// 		console.log(data.response.venue);
			// 		location = {
			// 			categories: data.response.venue.categories,
			// 			id: data.response.venue.id,
			// 			location: data.response.venue.location,
			// 			name: data.response.venue.name,
			// 			images: []
			// 		};

			// 		position = {
			// 			longitude: data.response.venue.location.lng,
			// 			latitude: data.response.venue.location.lat,
			// 			city: data.response.venue.location.city,
			// 			country: data.response.venue.location.country,
			// 			cc: data.response.venue.location.cc
			// 		};

			// 		savePosition();

			// 		if (position.city) {
			// 			console.log("hittade position.city");
			// 			setLocationData();
			// 			loadFromFoursquareConvert();
			// 		} else {
			// 			console.log("!!!!!!!!!!! HITTADE INTE!!!!!!!!!!!!");
			// 			getPositionFullFromLongLat(position.longitude, position.latitude, function() {
			// 				console.log("callback...");
			// 				endLoadOne();
			// 				loadFromFoursquareConvert();
			// 			});
			// 			//getPositionName();
			// 		}

			// 	},
			// error: function(jqXHR, textStatus, errorThrown) {
			// 	showError("ERROR loadFromFoursquare: " + textStatus);
			// }
			// });
		}
	};

	var loadFromFoursquareExisting = function(id, categories, loc, name) {
		console.log("loadFromFoursquareExisting() " + id);
		if (id) {
			console.log("---- det fanns");
			location = {
				categories: categories,
				id: id,
				location: loc,
				name: name,
				images: []
			};
		} else {
			console.log("---- det fanns inte");
		}

		isPushing = true;
		Path.history.pushState({}, "Worldcam - Search Instagram by location" + location.id, "/id/" + location.id);
		isPushing = false;

		startLoad();
		endLoadOne();
		convertLocation();

		//endLoadOne();
		//convertLocation();
	}

	var loadFromFoursquareConvert = function() {
		console.log("loadFromFoursquareConvert()");

		endLoadOne();
		convertLocation();
	};

	var convertLocation = function() {
		console.log("convertLocation()");
		var searchURL = "https://api.instagram.com/v1/locations/search";
		// showError("ERROR: Failed to convert location. This is probably an API limit - please come back in an hour!")
		$("#feedresults").html("");
		$.ajax({
			url: searchURL,
			type: "GET",
			dataType: "jsonp",
			cache: false,
			timeout: 5000,
			data: {
				foursquare_v2_id: location.id,
				client_id: "22aaafad8e8447cf883c2cbb55663de5"

			},
			success: function(data) {
				console.log("convertlocation succeeded!");
				console.log("data.data.length: " + data.data.length + " och sen data:");
				console.log(data);
				if (data.data.length > 0) {
					// Om den här är > 0 så hittade vi alltså ett instagram ID för den här foursquare ID'n.
					location.instaid = data.data[0].id;
					bufferLocation();
					loadImages();
				} else {
					endLoadNoFiles(true);
				}
			},
			error: function(data) {
				showError("ERROR: Failed to convert location. This is probably an API limit - please come back in an hour!")
				console.log("CONVERT LOCATION ERROR");
			}
		});
	};

	var loadImages = function(startid) {
		console.log("loadImages()");
		var searchURL = "https://api.instagram.com/v1/locations/" + location.instaid + "/media/recent/";
		console.log(searchURL + "?client_id=22aaafad8e8447cf883c2cbb55663de5");

		var loadData = {client_id: "22aaafad8e8447cf883c2cbb55663de5"};

		if (location.pagination) {
			console.log("JA, skickar in en next: " + location.pagination.next_max_id);
			loadData.max_id = location.pagination.next_max_id;
		}

		$.ajax({
			url: searchURL,
			type: "GET",
			dataType: "jsonp",
			cache: false,
			data: loadData,
			success: function(data) {
				console.log("loadImages success");
				console.log(data);
				console.log("och pagination: " + data.pagination);
				location.pagination = data.pagination;
				showImages(data.data);
			},
			error: function(jqXHR, textStatus, errorThrown) {
				showError("ERROR loadImages: " + textStatus);
			}
		});
	};

	var showImages = function(images) {
		console.log("showImages()");
		//console.log(images);

		if (location.images.length == 0 && images.length == 0) {
			endLoadNoFiles(false);
		}

		location.images = location.images.concat(images);

		$("#feed").css("display", "block");
		$("#feedlist").append(renderLocation(images));
		endLoadFiles();
	};

	var loadMoreLocation = function() {
		console.log("loadMoreLocation()");
		startLoadMore();

		loadImages();
	};

	var bufferLocation = function() {
		console.log("bufferLocation()");

		savedLocations[location.id] = {
			location: location,
			position: position
		};
	};

	var getPositionFullFromLongLat = function(lng, lat, callback) {
		console.log("getPositionFullFromLongLat() " + lng + ", " + lat);
		console.log(position);

		geocoder = new google.maps.Geocoder();
		var latlng = new google.maps.LatLng(lat, lng);
        geocoder.geocode({'latLng': latlng}, function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
        	console.log("testar...");
            if (results[1]) {
				console.log("HITTADE...");
				console.log(results);
				// console.log(results[1].address_components[3].long_name);
				var numlast = results[1].address_components.length - 1;
				position = {
					longitude: lng,
					latitude: lat,
					city: results[1].address_components[0].long_name,
					region: results[1].address_components[0].long_name
				};
				for (var i = 0; i < results[1].address_components.length; i++) {
					if (results[1].address_components[i].types[0] == "country") {
						position.country = results[1].address_components[i].long_name;
						position.cc = results[1].address_components[i].short_name;
					} else if (results[1].address_components[i].types[0] == "locality" || results[1].address_components[i].types[0] == "administrative_area_level_2") {
						position.city = results[1].address_components[i].long_name;
					} else if (results[1].address_components[i].types[0] == "sublocality") {
						position.region = results[1].address_components[i].long_name;
					}
					console.log(results[1].address_components[i].types[0]);
				}
				//					country: results[1].address_components[numlast].long_name,
				//	cc: results[1].address_components[numlast].short_name
				callback();
            } else {
              showError('No results found');
            }
          } else {
            showError('Geocoder failed due to: ' + status);
          }
        });

		// $.ajax({
		// 	type: "GET",
		// 	dataType: "jsonp",
		// 	cache: false,
		// 	url: "http://api.geonames.org/findNearbyPlaceNameJSON",
		// 	data: {
		// 		lat:lat,
		// 		lng:lng,
		// 		username:"gori"
		// 	},
		// 	success: function(data) {
		// 		console.log("getPositionFullFromLongLat succeded");
		// 		console.log(data.geonames[0]);

		// 		position = {
		// 			longitude: lng,
		// 			latitude: lat,
		// 			city: data.geonames[0].name,
		// 			region: data.geonames[0].adminName1,
		// 			country: data.geonames[0].countryName,
		// 			cc: data.geonames[0].countryCode
		// 		};
		// 		callback();

		// 	},
		// 	error: function(jqXHR, textStatus, errorThrown) {
		// 		showError("ERROR getPositionFullFromLongLat: " + textStatus);
		// 	}
		// });
	};

	var showLocationInfo = function() {
		console.log("showLocationInfo()");
		console.log(location);
		console.log(position);
		$("#location").css("display", "block");
		var catName;
		var address;
		if(location.categories.length) {
			address = location.categories[0].name + "<br>";
			locImage = location.categories[0].icon.prefix + "64" + location.categories[0].icon.name;
		} else {
			address = "";
			locImage = "/images/backup_64.png";
		}
		document.title = "Worldcam - " + location.name;
		$("#locationimage").attr("src", locImage);
		$("#locationname").html("<span class='locationnamelink'><a target='_blank' class='textlink' href='https://foursquare.com/v/" + location.id + "'>" + location.name + "</a>&nbsp;<img src='/images/poweredByFoursquare_16x16.png'></span>");
		if (location.location.address)
			address += location.location.address + "<br>";
		if (location.location.postalCode)
			address += location.location.postalCode + ' ';
		if (location.location.city)
			address += location.location.city + " ";
		if (location.location.state)
			address += " " + location.location.state;
		address += "<br>" + location.location.country;
		$("#locationaddress").html(address);
		//  + ' <span class="locationcategory">' + catName.split(" ").join("&nbsp;") + '</span>');
		// $("#locationaddress").html((location.location.address || "") + '<br>' + (location.location.postalCode || "") + ' ' + (location.location.city || "") + ', ' + (location.location.state || "") + '<br>' + (location.location.country || "") + ' ');
		console.log("TESTZ: " + mapMarker);
		moveMap();
	};

	var hideLocationInfo = function() {
		$("#location").css("display", "none");
	};

	var loadGeoLocation = function() {
		console.log("loadGeoLocation()");
		var searchURL = "https://api.instagram.com/v1/media/search";
		console.log(searchURL + "?client_id=22aaafad8e8447cf883c2cbb55663de5");
		console.log(location);

		hideSearch();
		hideLocationInfo();
		showLoader();
		hideError();
		clearLocation();
		$("#feedmore").css("display", "none");
		$("#feednone").css("display", "none");

		$.ajax({
			url: searchURL,
			type: "GET",
			dataType: "jsonp",
			cache: false,
			data: {
				client_id: "22aaafad8e8447cf883c2cbb55663de5",
				lat: location.location.lat,
				lng: location.location.lng,
				distance: 10

			},
			success: function(data) {
				console.log("success");
				console.log(data);
				location.data = data.data;
				showLocation();
			},
			error: function(jqXHR, textStatus, errorThrown) {
				showError("ERROR loadGeoLocation: " + textStatus);
			}
		});
	};

	var renderLocation = function(locList) {
		var listObject;
		var imageObject;
		var feedObject;
		var description;
		var nameLink;
		var renderResult = [];

		for (var i = 0; i < locList.length; i++) {
			if (locList[i].videos) {
				console.log(i + " - har video!!!");
			}
			if (locList[i].caption) {
				description = locList[i].caption.text;
			} else {
				description = "";
			}
			if (locList[i].user.website.length > 3) {
				nameLink = '<a class="whitelink" href="' + locList[i].user.website + '" target="_blank">' + locList[i].user.full_name + '</a>';
			} else {
				nameLink = locList[i].user.full_name;
			}
			listObject = $('<li class="feedlistitem mainshadow mainblock mainblockblack"></li>');
			if (locList[i].videos) {
				imageObject = $('<div id="feed' + i + '" class="feeditem insetimage"><video src="' + locList[i].videos.standard_resolution.url + '" poster="' + locList[i].images.standard_resolution.url + '" width="612" height="612" controls preload="auto">Sorry...</video></div>');
			} else {
				imageObject = $('<div id="feed' + i + '" class="feeditem insetimage" style="background-image:url(' + locList[i].images.standard_resolution.url + ')"><a href="' + locList[i].link + '"></a></div>');
			}
			//imageObject.click(function() { $(this).find('a').first().trigger('click'); });
			(function(linkurl) {
				imageObject.bind('click', {}, function() {
					window.open(linkurl);
				});
			})(locList[i].link);
			feedObject = '<div class="profile">';
			feedObject += '<div id="profile' + i + '" class="profileimage insetimage" style="background-image:url(' + locList[i].user.profile_picture + ')"></div>';
			feedObject += '<div class="profileinfo">';
			feedObject += '<p class="profileuser profileline">' + nameLink + ' (<a target="_blank" class="whitelink" href="http://instagram.com/' + locList[i].user.username + '">@' + locList[i].user.username + '</a>)</p>';
			feedObject += '<p class="profilecaption profileline">' + description + '</p>';
			feedObject += '</div>';
			feedObject += '<div class="profiledate">' + relativeDate(+locList[i].created_time * 1000) + '</div>';
			feedObject += '</div>';
			listObject.html(imageObject);
			listObject.append($(feedObject));
			// listObject.find(".profileuser").emoji();
			// listObject.find(".profilecaption").emoji();
			renderResult.push(listObject);
		}
		//return htmlResult;
		return renderResult;
	};

	var onHome = function() {
		console.log("onHome()");
		if (isAbout) {
			hideAbout();
		}
		Path.history.pushState({}, "Worldcam - Search Instagram by location", "/");
	};

	var sharePage = function(event) {
		var shareName = "Worldcam";
		var sharer = event.data.site;
		var shareURL = encodeURIComponent(getShareUrl());
		var shareTitle = "Find out what's happening right now at " + location.name + ", " + position.country;
		var shareImage = window.location.protocol + '//' + window.location.host + '/images/facebook.png';
		console.log("sharePage() " + sharer);
		console.log("shareURL är " + shareURL);

		if (sharer == "facebook") {
			var fName = encodeURIComponent(location.name + ", " + position.country);
			var fCaption = encodeURIComponent(shareName);
			var fDescription = encodeURIComponent("Find out what's happening right now on the other side of the world, or just around the corner.");
			//window.open("https://www.facebook.com/sharer/sharer.php?u=" + shareURL + "&t=" + shareTitle,"_blank");
			var facebookShare = "https://www.facebook.com/dialog/feed?app_id=396728627060915&link=" + shareURL + "&picture=" + shareImage + "&name=" + fName + "&caption=" + fCaption + "&description=" + fDescription + "&redirect_uri=http://worldc.am";

			window.open(facebookShare, "_blank");
		} else if (sharer == "twitter") {
			var shareLeft = (screen.width/2)-280;
			var shareTop = (screen.height/2)-140;
			window.open('http://twitter.com/share?url=' + encodeURIComponent(shareURL) + '&hashtags=worldcam&text=' + encodeURIComponent(shareTitle) + " " + shareURL,"Twitter Share", "left=" + shareLeft + ",top=" + shareTop + ",width=560,height=280,scrollbars=no");
		} else if (sharer == "pinterest") {
			window.open('http://pinterest.com/pin/create/button/?url=' + shareURL + '&media=' + shareImage + '&description=' + shareTitle,"_blank");
		}
	};

	var pushID = function(id) {
		console.log("pushID " + id);
		trendingResults = [];
		Path.history.pushState({}, "Worldcam - Search Instagram by location", "/id/" + id);
	};

	var onAbout = function() {
		if (isAbout) {
			hideAbout();
		} else {
			showAbout();
		}
	};

	var showAbout = function() {
		console.log("showAbout()");
		var diffY = $window.height() - 40;
		diffY = 574;
		//$("body").css("overflow", "hidden");
		$("#about").animate({ height: diffY }, 500);
		$("#back").animate({ top: diffY }, 500);

		isAbout = true;
	};

	var hideAbout = function() {
		console.log("showAbout()");
		//$("body").css("overflow", "visible");
		$("#about").animate({ height: 0 }, 400);
		$("#back").animate({ top: 0 }, 400);

		isAbout = false;
	};

	var startPromoted = function(showLocations) {
		console.log("startPromoted()");
		var showLocations = [
			{name:"The Great Wall", id:"4bb04b99f964a5200e403ce3", city:"Beijing", country:"China"},
			{name:"Bondi Beach", id:"4b058763f964a520848f22e3", city:"Sydney", country:"Australia"},
			{name:"Taj Mahal", id:"4b53fce2f964a52014b027e3", city:"Agra", country:"India"},
			{name:"Disney World", id:"4d91f168cbc1224bd50224d5", city:"Orlando", country:"United States"},
			{name:"Statue of liberty", id:"42893400f964a52054231fe3", city:"New York", country:"United States"},
			{name:"Empire State Building", id:"43695300f964a5208c291fe3", city:"New York", country:"United States"},
			{name:"Central Park", id:"412d2800f964a520df0c1fe3", city:"New York", country:"United States"},
			{name:"The White House", id:"3fd66200f964a520d6f01ee3", city:"Washington", country:"United States"},
			{name:"Big Ben", id:"4ac518cef964a520f6a520e3", city:"London", country:"United Kingdom"},
			{name:"London Eye", id:"4ac518cef964a52021a620e3", city:"London", country:"United Kingdom"},
			{name:"Buckingham Palace", id:"4abe4502f964a520558c20e3", city:"London", country:"United Kingdom"},
			{name:"Area 51", id:"4e569792d164a0684c612e71", city:"Rachel", country:"Nevada"},
			{name:"Caesars Palace", id:"41326e00f964a520da131fe3", city:"Las Vegas", country:"United States"},
			{name:"Sistine Chapel", id:"4bd6f610637ba593c5f7f870", city:"Vatican", country:"Vatican City"},
			{name:"Fontana di Trevi", id:"4adcdac6f964a5202b5321e3", city:"Rome", country:"Italy"},
			{name:"Colosseum", id:"4adcdac6f964a520355321e3", city:"Rome", country:"Italy"},
			{name:"Ministry of Sound", id:"4ac518b9f964a520bba120e3", city:"London", country:"United Kingdom"},
			{name:"Madison Square Garden", id:"4ae6363ef964a520aba521e3", city:"New York", country:"United States"},
			{name:"Burj Khalifa", id:"4b94f4f8f964a5204b8934e3", city:"Dubai", country:"United Arab Emirates"},
			{name:"Victoria Falls", id:"4bd6df0e6798ef3b61b8658d", city:"Victoria Falls", country:"Zimbabwe"},
			{name:"Leaning tower of Pisa", id:"4b4ae398f964a5208a8f26e3", city:"Pisa", country:"Italy"},
			{name:"Westminster Abbey", id:"4ac518cdf964a520eea520e3", city:"London", country:"United Kingdom"},
			{name:"Notre-Dame", id:"4adcda09f964a520e83321e3", city:"Paris", country:"France"},
			{name:"Moulin Rouge", id:"4b80718df964a520e57230e3", city:"Paris", country:"France"},
			{name:"Eiffel Tower", id:"4adcda09f964a520dd3321e3", city:"Paris", country:"France"},
			{name:"Louvre", id:"4adcda10f964a520af3521e3", city:"Paris", country:"France"},
			{name:"The Duomo", id:"4b05887cf964a520eec822e3", city:"Milan", country:"Italy"},
			{name:"Las Vegas Strip", id:"4b6ed09ff964a520c5cb2ce3", city:"Las Vegas", country:"United States"},
			{name:"Times Square", id:"49b7ed6df964a52030531fe3", city:"New York", country:"United States"},
			{name:"Golden Gate Bridge", id:"49d01698f964a520fd5a1fe3", city:"San Francisco", country:"United States"},
			{name:"Alcatraz", id:"4451c80ef964a520a5321fe3", city:"San Francisco", country:"United States"},
			{name:"Angkor wat", id:"501bc2e3e4b0ef2dfe5f0b23", city:"Siem Reap", country:"Cambodia"},
			{name:"Forbidden City", id:"4bd877965cf276b0ac539d00", city:"Beijing", country:"China"},
			{name:"Gateway Arch", id:"4acbc3fbf964a52013c620e3", city:"St Louis", country:"United States"},
			{name:"Space Needle", id:"416dc180f964a5209b1d1fe3", city:"Seattle", country:"United States"},
			{name:"Hollywood Sign", id:"4afee5f7f964a5205a3122e3", city:"Los Angeles", country:"United States"},
			{name:"Venice Beach", id:"4c040b64187ec928b87fb67b", city:"Venice", country:"United States"},
			{name:"South Beach", id:"4bd34c729854d13a8e6efd4d", city:"Miami", country:"United States"},
			{name:"Coney Island", id:"4d5be3ed1da1cbff94501a05", city:"New York", country:"United States"},
			{name:"Grand Canyon", id:"4cf1603fd29b2d438fe0f0bb", city:"Grand Canyon", country:"United States"},
			{name:"Niagara Falls", id:"4b1ad12ef964a52070f223e3", city:"Niagara Falls", country:"United States"},
			{name:"Mount Rushmore", id:"4bd5c0495631c9b6419ba430", city:"Rapid City", country:"United States"},
			{name:"Badlands", id:"4f624209e4b011d851538a9c", city:"Rapid City", country:"United States"},
			{name:"Copacabana", id:"4b2ff8faf964a520a8f324e3", city:"Rio de Janeiro", country:"Brazil"},
			{name:"Cristo Redentor", id:"4d29b8ef3c795481133ada9b", city:"Rio de Janeiro", country:"Brazil"},
			{name:"Waikiki Beach", id:"50046699e4b0bfb884f1be89", city:"Honolulu", country:"United States"},
			{name:"Sydney Opera House", id:"4b058762f964a5201b8f22e3", city:"Sydney", country:"Australia"},
			{name:"Boulders Beach", id:"4b98f6f8f964a520f85835e3", city:"Cape Town", country:"South Africa"},
			{name:"Harajuku", id:"4e5f5340b0fb27e2bd450341", city:"Tokyo", country:"Japan"},
			{name:"Western Wall", id:"4b896c78f964a520ff3432e3", city:"Jerusalem", country:"Israel"},
			{name:"Playboy Mansion", id:"4a60fb75f964a5209dc11fe3", city:"Los Angeles", country:"United States"},
			{name:"Pacha", id:"4b7f23f4f964a5209e1930e3", city:"Ibiza", country:"Spain"},
			{name:"Berghain", id:"4ae778a5f964a520a5ab21e3", city:"Berlin", country:"Germany"},
			{name:"Egyptian Pyramids", id:"4fa1373be4b00c2d65d5a5a1", city:"Cairo", country:"Egypt"},
			{name:"Red Light District", id:"4c78d269df08a1cdf5b6d85d", city:"Amsterdam", country:"The Netherlands"},
			{name:"Stonehenge", id:"4baca654f964a520c7003be3", city:"Amesbury", country:"United Kingdom"},
			{name:"Machu Picchu", id:"4efa109877c8e88f4a05a6b7", city:"Aguas Calientes", country:"Peru"},
			{name:"Red Square", id:"5016a074e4b001b33a3f20d7", city:"Moscow", country:"Russia"},
			{name:"Paradiso", id:"4a27db90f964a5208e941fe3", city:"Amsterdam", country:"Netherlands"},
			{name:"Skansen", id:"4adcdaeff964a5200e5b21e3", city:"Stockholm", country:"Sweden"},
			{name:"Pinacoteca do Estado", id:"4b0588c7f964a520e8d922e3", city:"São Paulo", country:"Brazil"},
			{name:"Parque Ibirapuera", id:"4b0588c7f964a520d9d922e3", city:"São Paulo", country:"Brazil"},
			{name:"Saint Basil's Cathedral", id:"4bee5d152c082d7f2b5d3042", city:"Moscow", country:"Russia"},
			{name:"Bukhara", id:"4e39868eb61c438b5487db5d", city:"Bukhara", country:"Uzbekistan"},
			{name:"Kaaba", id:"4ec52bc27ee571eed68677f7", city:"Mecca", country:"Saudi Arabia"},
			{name:"Staroměstské náměstí", id:"4bbdfa09f57ba593a6b3aeb9", city:"Prague", country:"Czech Republic"},
			{name:"Chernobyl", id:"4cc2a83542d1b60c77f11113", city:"Pripyat", country:"Ukraine"},
			{name:"Kunstkamera", id:"4befdc8151f2c9b65ff4f092", city:"St Petersburg", country:"Russia"},
			{name:"Hermitage", id:"4d9abff1422ea1cd52d9ec4c", city:"St Petersburg", country:"Russia"},
			{name:"Montmartre", id:"4c68251df984a593a80b49f4", city:"Paris", country:"France"},
			{name:"Vitabergsparken", id:"4adcdaeff964a520d75a21e3", city:"Stockholm", country:"Sweden"},
			{name:"Borough Market", id:"4ac518eff964a52064ad20e3", city:"London", country:"England"},
			{name:"Grand Bazaar", id:"4c09fd76009a0f476ac2e8bf", city:"Istanbul", country:"Turkey"},
			{name:"Jama Masjid Mosque", id:"4b529b68f964a520b48327e3", city:"Delhi", country:"India"},
			{name:"Van Gogh Museum", id:"4a2706faf964a5208c8c1fe3", city:"Amsterdam", country:"Netherlands"},
			// {name:"Blue Mosque", id:"4b753a2af964a520d4012ee3", city:"Istanbul", country:"Turkey"},
			{name:"Acropolis", id:"4adcdadff964a5205b5821e3", city:"Athens", country:"Greece"},
			{name:"Blue Lagoon", id:"4b5c57ecf964a520ba2b29e3", city:"Grindavík", country:"Iceland"},
			{name:"Grouse Mountain", id:"4aae660bf964a520fa6120e3", city:"Vancouver", country:"Canada"},
			{name:"Parc Güell", id:"4b76bca2f964a520975b2ee3", city:"Barcelona", country:"Spain"},
			{name:"Boom Boom Room", id:"504ff8dde4b052774b63bc20", city:"New York", country:"United States"},
			{name:"Miami Ink", id:"4b5a8920f964a52042ca28e3", city:"Miami", country:"United States"},
			{name:"Graceland", id:"4b058660f964a520465f22e3", city:"Memphis", country:"United States"},
			{name:"Monte-Carlo", id:"4f37c604e4b0571dc7ca7b56", city:"Monte-Carlo", country:"Monaco"},
			{name:"Pamukkale", id:"4fe74e49e4b067dfbee16b89", city:"Pamukkale", country:"Turkey"},
			{name:"Facebook HQ", id:"4e37101cb0fbcceaf0dd3d13", city:"Palo Alto", country:"United States"},
			{name:"Apple HQ", id:"49b15db9f964a520d5521fe3", city:"Cupertino", country:"United States"},
			{name:"Googleplex", id:"40870b00f964a5209bf21ee3", city:"Mountain View", country:"United States"},
			{name:"Twitter HQ", id:"4ee0ecde29c2c6e332924109", city:"San Francisco", country:"United States"},
			// {name:"Foursquare HQ", id:"4ef0e7cf7beb5932d5bdeb4e", city:"New York", country:"United States"},
			{name:"Camp Nou", id:"4adcda60f964a520934421e3", city:"Barcelona", country:"Spain"},
			{name:"San Siro", id:"4c09623f3c70b713c3cf275b", city:"Milan", country:"Italy"},
			{name:"Yankee Stadium", id:"3fd66200f964a520ddf01ee3", city:"Bronx", country:"United States"},
			{name:"Ayers Rock", id:"4bd15387b221c9b6fe6ad5d0", city:"Uluru", country:"Australia"},
			{name:"Bora Bora", id:"4e9ac766e5fa3f633d4c8651", city:"Bora Bora", country:"French Polynesia"},
			{name:"Santorini", id:"50363d7ae4b0584f7dd36db8", city:"Thira", country:"Greece"},
			{name:"Gullfoss", id:"4bb5ee0c46d4a5933f74c5c0", city:"Gullfoss", country:"Iceland"},
			{name:"Geysir", id:"4bb6027e2f70c9b6eabd8430", city:"Geysir", country:"Iceland"},
			{name:"Seljalandsfoss", id:"4c877e43f554236a6600cd55", city:"Stóri-Dalur", country:"Iceland"},
			{name:"Moraine Lake", id:"4bfac9445317a5938a2a037f", city:"Lake Louise", country:"Canada"},
			{name:"Petra", id:"4ba4a248f964a520bba838e3", city:"Petra", country:"Jordan"},
			{name:"Versailles", id:"4adcda09f964a520df3321e3", city:"Versailles", country:"France"},
			{name:"Moeraki Boulders", id:"4da1233e9935a0937e949a6f", city:"Hampden", country:"New Zealand"},
			{name:"Las Cañadas", id:"4d04bc9fc2e537047160ba67", city:"Tenerife", country:"Spain"},
			{name:"Table Mountain", id:"4bb0fba2f964a5204f703ce3", city:"Cape Town", country:"South Africa"},
			{name:"Arc de Triomphe", id:"4adcda09f964a520de3321e3", city:"Paris", country:"France"},
			{name:"Mount Fuji", id:"4d1befe4c17ff04ddacfc241", city:"Fujikawaguchiko", country:"Japan"},
			{name:"First Starbucks", id:"440daad8f964a52096301fe3", city:"Seattle", country:"United States"},
			{name:"Microsoft HQ", id:"4ad21e8cf964a5207ddf20e3", city:"Seattle", country:"United States"},
			{name:"Iguazú Falls", id:"4cf0ea826c29236ae36b62a2", city:"Puerto Iguazú", country:"Argentina"},
			{name:"Serengeti", id:"4b69a4c1f964a52002ab2be3", city:"Arusha", country:"Tanzania"},
			{name:"Kruger Park", id:"4c6533cd508f76b0a25db5a6", city:"Krokodilbrug", country:"South Africa"},
			{name:"Great Barrier Reef", id:"4b33f317f964a520a92225e3", city:"Great Barrier Reef", country:"Australia"},
			{name:"Easter Island", id:"4e6585346365c9191287b8d9", city:"Easter IsIand", country:"Chile"},
			{name:"Milford Sound", id:"4b5e98faf964a520949329e3", city:"Milford Sound", country:"New Zealand"},
			{name:"Chichen Itza", id:"4bdef048e75c0f47b155c903", city:"Chichen Itza", country:"Mexico"},
			{name:"Wulingyuan", id:"4edaee8a61af8a14b70a067a", city:"Wujiayu", country:"China"},
			{name:"Petronas Towers", id:"4f52c36ce4b0ef9671d9bec0", city:"Kuala Lumpur", country:"Malaysia"},
			{name:"Pentagon", id:"4b1544bbf964a5201caa23e3", city:"Arlington", country:"United States"},
			{name:"Piccadilly Circus", id:"4ac518cdf964a520efa520e3", city:"London", country:"United Kingdom"},
			{name:"Hyde Park", id:"4ac518d2f964a52026a720e3", city:"London", country:"United Kingdom"},
			{name:"Paddington", id:"4ae83e74f964a5204bae21e3", city:"London", country:"United Kingdom"},
			{name:"Wembley", id:"4b03382df964a520a74d22e3", city:"London", country:"United Kingdom"},
			{name:"Grand Central", id:"42829c80f964a5206a221fe3", city:"New York", country:"United States"},
			{name:"MoMA", id:"4af5a46af964a520b5fa21e3", city:"New York", country:"United States"},
			{name:"Harvard", id:"4a5b6b91f964a52026bb1fe3", city:"Boston", country:"United States"},
			{name:"Late Show with Letterman", id:"4a9300c2f964a520741e20e3", city:"New York", country:"United States"},
			{name:"Paramount Studios", id:"4a1ee7faf964a520e77b1fe3", city:"Los Angeles", country:"United States"},
			{name:"Marquee", id:"4d013eda6289f04d14be96cc", city:"Las Vegas", country:"United States"},
			{name:"Ace Swim Club", id:"4ae8ea37f964a5204cb321e3", city:"Palm Springs", country:"United States"},
			{name:"Shark Alley", id:"4cda65745aeda1cd4a99b611", city:"Gansbaai", country:"South Africa"},
			{name:"Kilimanjaro", id:"4c53258dfee595217c9c27f2", city:"Machame", country:"Tanzania"},
			{name:"Staples Center", id:"42893400f964a5207e231fe3", city:"Los Angeles", country:"United States"},
			{name:"Kennedy Space Center", id:"4f2179a3e4b0b69d78926a81", city:"Merritt Island", country:"United States"},
			{name:"Berlin Wall", id:"4c8289ab647db713b33e09bb", city:"Berlin", country:"Germany"},
			{name:"Victoria Peak", id:"4b0588d1f964a52079db22e3", city:"The Peak", country:"Hong Kong"},
			{name:"Ipanema", id:"4b058724f964a520df8122e3", city:"Rio de Janeiro", country:"Brazil"},
			{name:"Jefferson Memorial", id:"4a106621f964a520ba761fe3", city:"Washington DC", country:"United States"},
			{name:"Cape of Good Hope", id:"4c2c9929d1a10f4761a9f964", city:"Cape Town", country:"South Africa"},
			{name:"Galápagos Islands", id:"4b9844c8f964a520793835e3", city:"Galápagos Islands", country:"Ecuador"},
			{name:"Loch Ness", id:"4ba7b4edf964a5208cab39e3", city:"Fort Augustus", country:"Scotland"},
			{name:"Old Trafford", id:"4ade0e34f964a520596f21e3", city:"Manchester", country:"United Kingdom"},
			{name:"Tiger's Nest", id:"4e19804052b123a586e0dece", city:"Drugyel Dzong", country:"Bhutan"},
			{name:"Meteor Crater", id:"4bb3d6e235f0c9b64ef6bc83", city:"Winslow", country:"United States"},
			{name:"Barcelona Beach", id:"4c0d3610d64c0f47665e265d", city:"Barcelona", country:"Spain"},
			{name:"Devils Tower", id:"4bb93e6453649c748ce247fb", city:"Sundance", country:"United States"},
			{name:"Haystack Rock", id:"4b37eb3ff964a5209f4825e3", city:"Cannon Beach", country:"United States"},
			{name:"Pixar Animation", id:"4693d828f964a520d3481fe3", city:"Emeryville", country:"United States"},
			{name:"Ice Hotel", id:"4adcdaeaf964a5209b5921e3", city:"Jukkasjärvi", country:"Sweden"},
			{name:"Marvel Entertainment", id:"49e898b0f964a52058651fe3", city:"New York", country:"United States"},
			{name:"Abbey Road Studios", id:"4ac518d0f964a520aaa620e3", city:"London", country:"United Kingdom"},
			{name:"Industrial Light & Magic", id:"4b50f073f964a520a13927e3", city:"San Francisco", country:"United States"},
			{name:"Ha Long Bay", id:"4ccda9247c2ff04d7a93a07e", city:"Hạ Long", country:"Vietnam"},
			{name:"Eagle Beach", id:"4c30b4a8ed37a593a63a6903", city:"Eagle Beach", country:"Aruba"},
			{name:"Stedelijk Museum", id:"4b5fe77bf964a5203fd029e3", city:"Amsterdam", country:"Netherlands"},
			{name:"Eagle Beach", id:"4c30b4a8ed37a593a63a6903", city:"Eagle Beach", country:"Aruba"},
			{name:"Eagle Beach", id:"4c30b4a8ed37a593a63a6903", city:"Eagle Beach", country:"Aruba"},];
		backObjects = showLocations.shuffle();

		var backObject;
		var backObjectList = [];
		var textLink = "";

		var numProm = 8;
		for (var i = 0; i < numProm; i++) {
			console.log("counter" + i + " - " + backObjects[i].name);
			backObject = $("<span class='textlink'>" + backObjects[i].name.split(" ").join("&nbsp;") + "</span>");
			(function(id) {
				backObject.bind('click', {}, function() {
					pushID(id);
				});
			})(backObjects[i].id);
			backObjectList.push(backObject);
			if (i < (numProm-2)) {
				backObjectList.push($("<span>, </span>"));
			} else if (i == (numProm-2)) {
				backObjectList.push($("<span> or </span>"));
			}
		}
		$("#promoted").html("<span class='promotedhow'>Or find out what's happening right now at:</span><br>");
		$("#promoted").append(backObjectList);
		$("#promotedmain").css("display", "block");
		$("header").css("display", "block");
	};

	var hidePromoted = function() {
		console.log("hidePromoted()");
		$("#promotedmain").css("display", "none");
		$("header").css("display", "none");
	};

	var getSharePath = function() {
		var l = window.location;
		var path;

		if (l.hash && l.hash.match(/#?\//)) {
			path = l.hash.replace('#', '');
		} else {
			path = l.pathname;
		}

		return path;
	};

	var getShareUrl = function() {
		var l = window.location;
		var url = l.protocol + '//' + l.host;
		url += Path.routes.current.replace('#', '');
		return url;
	}

	var disableForm = function() {
		$("#formob").css("opacity", "0.3");
		$("#form").css("pointer-events", "none");
		$("#back").css("pointer-events", "none");
		$("#logo").css("pointer-events", "none");
	}

	var enableForm = function() {
		$("#formob").css("opacity", "1");
		$("#form").css("pointer-events", "auto");
		$("#back").css("pointer-events", "auto");
		$("#logo").css("pointer-events", "auto");
	}

	var showLocationSearch = function(status) {
		hideLoader();
		$("#searchlocation").css("display", "block");
		$("#searchlocation").html("<p>" + status + "</p>");
	};

	var hideSearch = function() {
		$("#searchlocation").css("display", "none");
		$("#searchposition").css("display", "none");
	};

	var showPositionSearch = function(status) {
		hideLoader();
		$("#searchposition").css("display", "block");
		$("#searchposition").html("<p>" + status + "</p>");
	};

	var clearLocation = function() {
		$("#feed").css("display", "none");
	};

	var showError = function(status) {
		hideLoader();
		$("#error").css("display", "block");
		$("#error").html("<p class='centertext'>" + status + "</p>");
		//endLoadOne();
	};

	var hideError = function() {
		$("#error").css("display", "none");
	};

	var showLoader = function() {
		$("#loader").css("display", "block");
	};

	var hideLoader = function() {
		$("#loader").css("display", "none");
	};

	var startShow = function() {
		enableForm();
		$('#form').css('visibility', 'visible');
	};

	var isLocationField = function() {
		if (location) {
			return $("#formlocation").val() == location.name;
		} else {
			return false;
		}
	};

	var isPositionField = function() {
		return $("#formposition").val() == getPositionString();
	};

	var getLocationString = function(loc) {
		var name;
		if (loc.categories) {
			if(loc.categories.length > 0) {
				name =  loc.name + ", " + loc.categories[0].name;
			} else {
				name = loc.name;
			}
		} else {
			name = "";
		}
		return name;
	};

	var getPositionString = function() {
		// if (position.region) {
		// 	return htmlDecode(position.city + ", " + position.region + ", " + position.country);
		// } else {
			return htmlDecode(position.city + ", " + position.country);
		// }
	};

	encodePositionURL = function(name, country) {
		return encodeURIComponent(name)+","+encodeURIComponent(country);
	};

	decodePositionURL = function(urlString) {
		var returner = urlString.split(",");
		returner[0] = decodeURIComponent(returner[0]);
		returner[1] = decodeURIComponent(returner[1]);
		return returner;
	};

	var updateAnalytics = function(){
	    _gaq.push(['_trackPageview', document.location.href]);
	};

	var htmlDecode = function(input){
		var e = document.createElement('div');
		e.innerHTML = input;
		return e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
	};

	var fixConsole = function() {
		var noop = function noop() {};
		var methods = [
			'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
			'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
			'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
			'timeStamp', 'trace', 'warn'
		];
		var length = methods.length;
		var console = window.console || {};

		while (length--) {
			// Only stub undefined methods.
			console[methods[length]] = console[methods[length]] || noop;
		}
	};

	Array.prototype.shuffle = function() {
		var i = this.length, j, tempi, tempj;
		if ( i == 0 ) return false;
		while ( --i ) {
			j       = Math.floor( Math.random() * ( i + 1 ) );
			tempi   = this[i];
			tempj   = this[j];
			this[i] = tempj;
			this[j] = tempi;
		}
		return this;
	};

	// On DOM ready
	$(autorun);

})(this, jQuery);
