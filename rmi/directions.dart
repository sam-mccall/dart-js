// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:html');
#import('maps.dart');

DirectionsRenderer directionsDisplay;
DirectionsService directionsService;

calcRoute(_) {
  final panel = query('#directions_panel');
  SelectElement start = query('#start');
  SelectElement end = query('#end');
  final request = {
    'origin': start.value,
    'destination': end.value,
    'travelMode': DirectionsTravelMode.DRIVING
  };
  panel.innerHTML = "<b>Thinking...</b>";
  directionsService.route(request, (response, status) {
      if (status == DirectionsStatus.OK) {
        document.query('#directions_panel').innerHTML = "";
        directionsDisplay.setDirections(response);
      } else {
        document.query('#directions_panel').innerHTML =
            "<b>Err, try flying.</b>";
      }
    });
}

main() {
  injectSource(isolateTest);
  var myOptions = {
    'zoom': 9,
    'mapTypeId': MapTypeId.ROADMAP,
    'center': new LatLng(47.6097, -122.3331)
  };
  var element = document.query('#map_canvas');
  var map = new GMap(element, myOptions);

  directionsDisplay = new DirectionsRenderer();
  directionsDisplay.setMap(map); // TODO: get handle corresponding to map here.
  directionsDisplay.setPanel(document.query('#directions_panel'));
  directionsService = new DirectionsService();

  var control = document.query('#control');
  control.style.display = 'block';
  
  map.controls[ControlPosition.TOP].dynamic.push(control);

  query('#start').on.change.add(calcRoute);
  query('#end').on.change.add(calcRoute);
}


// This is temp test code.
injectSource(code) {
  final script = new ScriptElement();
  script.type = 'text/javascript';
  script.innerHTML = code;
  document.body.nodes.add(script);
}
var isolateTest = """
function test(data) {
  if (data == 'sent')
    return 'received';
}

function Scope() {
  this.handles = {};
  this.id = 0;
}
Scope.prototype.allocate = function(value) {
  var handle = this.id++;
  this.handles[handle] = value;
  return handle;
}
Scope.prototype.get = function(handle) {
  return this.handles[handle];
}
_scope = new Scope();
var methods = ['setMap', 'setPanel', 'push'];
for (var i=0; i < methods.length; i++) {
  var method = methods[i];
  var port = new ReceivePortSync();
  port.receive(function foo(listArgs) {
      var handle = _scope.get(listArgs['callingObject']);
      var handlesList = listArgs['handles'];
      for (var i = 0; i < handlesList.length; i++) {
        argsListIndex = handlesList[i];
        listArgs['args'][argsListIndex] = _scope.get(listArgs['args'][argsListIndex]);
      }
      var the_method = handle[method];
      var result = the_method.apply(handle, listArgs['args']);// _scope.get(listArgs['callingObject']).method(listArgs['args']);//TODO call on a particular object? full name? also test whether there's an object calling it or if it's just a static function
      return {'_id': _scope.allocate(result), 'result': result};
  });
  window.registerPort(method, port.toSendPort());
}

//for (method in all_methods) { // TODO (this will have to be done programmatically...?)

//TODO: 'free' method to free elements in this array.
""";
