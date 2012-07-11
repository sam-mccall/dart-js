#import('dart:html');
#import('../../rpc/rpc.dart', prefix: 'rpc');

class PanoramioDemo {
  final rpc.RPC panoramio;
  var mapHandle;
  var panoramioHandle;
  
  PanoramioDemo() : panoramio = new rpc.RPC.Client("pan");
  
  void updateLocation(String locationQuery) {
    panoramio.findLocation(locationQuery, (results, status) {
      print("callback invoked!");
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
    var mapOptions = {
      "zoom": 15,
      "mapTypeId": "roadmap"
     };
    mapHandle = panoramio.createMap('content', mapOptions, lat, lng);
    panoramioHandle = panoramio.createPanoramio(mapHandle);
  }
  
  void load() {
    document.query("#location-button").on.click.add((event) => updateLocation(document.query("#location").value)); 
    document.query("#filter-button").on.click.add((event) {
      InputElement input = document.query("#tag");
      panoramio.setTag(input.value, panoramioHandle);
    });
    document.query("#user-id-button").on.click.add(
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
