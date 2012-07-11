#import('dart:html');
#import('../../rpc/rpc.dart', prefix: 'rpc');

class PanoramioDemo {
  final rpc.RPC panoramio;
  var mapHandle;
  var panoramioHandle;
  
  PanoramioDemo() : panoramio = new rpc.RPC.Client("pan");
  
  void updateLocation(String locationQuery) {
    panoramio.findLocation(locationQuery, (results, status) {
      if (status == "OK") {
        print(status);
        print("results $results");
        Map latlon = results[0]["geometry"]["location"];
        loadMap(latlon["lat"], latlon["lng"]);
      } else {
        print("ERRORRRRR");
      }
    });
  }
  
  void loadMap(lat, lng) {
    mapHandle = panoramio.createMap('content', {
      "zoom": 15,
      "mapTypeId": "roadmap",
      "center": {"\$type": "latlng", "lat": lat, "lng": lng},
     });
    panoramioHandle = panoramio.createPanoramio(mapHandle);
  }
  
  void load() {
    document.query("#location").on.change.add((event) => updateLocation(document.query("#location").value));
    document.query("#tag").on.change.add((event) {
      InputElement input = document.query("#tag");
      panoramio.setTag(input.value, panoramioHandle);
    });
    document.query("#userId").on.change.add(
      (event) => panoramio.setUserId(document.query("#userId").value, panoramioHandle));
    updateLocation("New York");
  }
}

void main() {
  print("started in dart");
  PanoramioDemo demo = new PanoramioDemo();
  demo.load();  
  //service.__release__(handle);
}
