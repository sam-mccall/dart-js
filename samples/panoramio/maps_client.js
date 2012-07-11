/*
function drawRoute () {
  console.log("routing");
  var panel = document.getElementById('directions_panel');
  var start = document.getElementById('start');
  var end = document.getElementById('end');
  console.log("panel: ", panel);
  
  var directionsService = new rpc.Client('maps').connect();
  console.log(start.value, end.value);
  directionsService.route(start.value, end.value, "DRIVING", 'directions_panel'
}*/

function loadPanoramioView() {
  panoramioService = new rpc.Client('panoramio').connect();
  var mapOptions = {
    zoom: 15,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
  };
  panoramioService.createMap('content', mapOptions, 40.693134, -74.031028);
  document.getElementById("filter-button").onclick = function() {
    panoramioService.setTag(document.getElementById("tag").value);
  };
  document.getElementById("user-id-button").onclick = function() {
    panoramioService.setUserId(document.getElementById("userId").value);
  };
}

//window.onload = loadPanoramioView;
