var PanoramioService = new rpc.Service('pan', {
    setTag: function(tagFilter, panoramioLayer) {
      panoramioLayer.setTag(tagFilter);
    },
    createPanoramio: function(map) {
      var panoramioLayer = new google.maps.panoramio.PanoramioLayer();
      panoramioLayer.setMap(map);
      return PanoramioService.handle(panoramioLayer);
    },
    createMap: function(mapContainer, mapOptions) {
      var map = new google.maps.Map(document.getElementById(mapContainer), mapOptions);
      return PanoramioService.handle(map);
    },
    setUserId: function(userId, panoramioLayer) {
      panoramioLayer.setUserId(userId);
    },
    findLocation: function(query, callback) {
      new google.maps.Geocoder().geocode({'address': query}, function(results, status) {
        (status == google.maps.GeocoderStatus.OK) ? callback(results[0], null) : callback(null, status);
        callback.release();
      });
    },
    route: function(origin, destination, travelMode, callback) {
      var directions_service = new google.maps.DirectionsService();
      directions_service.route({
        'origin': origin,
        'destination': destination,
        'travelMode': travelMode
      }, function() { callback(); callback.release(); });
    },
    routeWithId: function(origin, destination, travelMode, mapContainerId) {
      var directions_service = new google.maps.DirectionsService();
      var options = {
          'origin': origin,
          'destination': destination,
          'travelMode': travelMode
      };
      directions_service.route(options, function(result, status) {
        var directionsDisplay = document.getElementById(mapContainerId);
        if (status != "OK") {
          directionsDisplay.innerHTML = "<b>Err, try flying.</b>";
          return;
        }
        directionsDisplay.innerHTML = "";
        directionsDisplay.setDirections(result);
      });
    },
});
PanoramioService.serializer.register(function(x) { return x instanceof google.maps.LatLng; }, function(latlng) {
  return {$type: 'latlng', lat: latlng.lat(), lng: latlng.lng()};
});
PanoramioService.deserializer.register(function(x) { return (x != null) && (x.$type == 'latlng'); }, function(latlng) {
  return new google.maps.LatLng(latlng.lat, latlng.lng);
});
PanoramioService.expose();
