
var PanoramioService = new function() {
  var createMap = function(mapContainer, mapOptions) {
    var map = new google.maps.Map(document.getElementById(mapContainer), mapOptions);
    return service.handle(map);
  };
  var setUserId = function(userId, panoramioLayer) {
    panoramioLayer.setUserId(userId);
  };
  var findLocation = function(query, callback) {
    new google.maps.Geocoder().geocode({'address': query}, function(results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        callback(results, status);
        callback.release();
      }
    });
  };
  var createPanoramio = function(map) {
    var panoramioLayer = new google.maps.panoramio.PanoramioLayer();
    panoramioLayer.setMap(map);
    return service.handle(panoramioLayer);
  };
  var service = new rpc.Service('pan', {
      setTag: function(tagFilter, panoramioLayer) {
        panoramioLayer.setTag(tagFilter);
      },
      createPanoramio: createPanoramio,
      createMap: createMap,
      setUserId: setUserId,
      findLocation: findLocation,
      route: function(origin, destination, travelMode, callback) {
        var directions_service = new google.maps.DirectionsService();
        var completer = new Completer();
        directions_service.route({
            'origin': origin,
            'destination': destination,
            'travelMode': travelMode
          }, function() {
             callback();
             callback.release();
          });
      },
      routeWithId: function(origin, destination, travelMode, mapContainerId) {
        console.log("routeWithId");
        var directions_service = new google.maps.DirectionsService();
        var options = {
            'origin': origin,
            'destination': destination,
            'travelMode': travelMode
        };
        directions_service.route(options, function(result, status) {
            var directionsDisplay = document.getElementById(mapContainerId);
            if (status == "OK") {
              directionsDisplay.innerHTML = "";
              directionsDisplay.setDirections(result);
            } else {
              directionsDisplay.innerHTML = "<b>Err, try flying.</b>";
           }
        });
      },
  });
  
  service.serializer.register(function(x) { return x instanceof google.maps.LatLng; }, function(latlng) {
    return {$type: 'latlng', lat: latlng.lat(), lng: latlng.lng()};
  });
  service.deserializer.register(function(x) { return (x != null) && (x.$type == 'latlng'); }, function(latlng) {
    return new google.maps.LatLng(latlng.lat, latlng.lng);
  });
  this.load = function() { service.expose(); }
}

foo = (function() {
  return {
    x: 10,
    y: 20,
  }
})();

PanoramioService.load();