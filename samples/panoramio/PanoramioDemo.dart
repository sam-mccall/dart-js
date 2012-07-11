#import('dart:html');
#import('../../rpc/rpc.dart', prefix: 'rpc');

class PanoramioDemo {
  final rpc.RPC panoramio;
  var mapHandle;
  var panoramioHandle;
  
  PanoramioDemo() : panoramio = new rpc.RPC.Client("pan");
  
  void updateLocation(String locationQuery) {
    // TODO(sammccall): make this a Future
    panoramio.findLocation(locationQuery, (result, error) {
      if (error != null) throw new Exception(error);
      final location = result["geometry"]["location"];
      loadMap(location["lat"], location["lng"]);
    });
  }
  
  void loadMap(lat, lng) {
    // TODO(sammccall): release the old handles, or reuse them
    mapHandle = panoramio.createMap('content', {
      "zoom": 15,
      "mapTypeId": "roadmap",
      "center": {"\$type": "latlng", "lat": lat, "lng": lng},
     });
    panoramioHandle = panoramio.createPanoramio(mapHandle);
  }
  
  void load() {
    document.query("#location").on.change.add((event) => updateLocation(document.query("#location").value));
    document.query("#tag").on.change.add((event) => panoramio.setTag(document.query("#tag").value, panoramioHandle));
    document.query("#userId").on.change.add((event) => panoramio.setUserId(document.query("#userId").value, panoramioHandle));
    updateLocation("New York");
  }
}

main() => new PanoramioDemo().load();
