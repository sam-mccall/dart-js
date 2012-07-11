// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A very incomplete Dart layer over the Google Maps JS API, v3.
// See https://developers.google.com/maps/documentation/javascript/reference
// for the underlying JS API.

#library('maps');
#import('dart:html');
#import('dart:isolate');
#import('proxy_js.dart');

class GMap extends ProxyJs {

//TODO release scope objects when done.
  GMap(element, options) : super('google.maps.Map', [element, options]) {
    // TODO: free when done.
  }

  List<MVCArray> get controls() => new MVCMapControlArrayList(this);
}

class LatLng {
  final num _lat;
  final num _lng;
  LatLng(this._lat, this._lng);
}

class LatLngBounds {
  final LatLng _sw;
  final LatLng _ne;
  LatLngBounds(this._sw, this._ne);
}

class MapTypeId {
  static final ROADMAP = 'roadmap';
}

class DirectionsService extends ProxyJs {
  ProxyJs _directionsService;
  DirectionsService() : super('google.maps.DirectionService');
}

class ControlPosition {
  static final TOP = 2;
}

class DirectionsResult {
}

class DirectionsTravelMode {
  static final DRIVING = 'DRIVING';
  static final BICYCLING = 'BICYCLING';
  static final WALKING = 'WALKING';
}

class DirectionsStatus {
  static final OK = 'OK';
}

class DirectionsRenderer extends ProxyJs {
  DirectionsRenderer() : super('google.maps.DirectionsRenderer');
} 

abstract class MVCArray extends ProxyJs {
}

class MVCMapControlArray extends MVCArray {
  GMap _map;
  final _key;
  MVCMapControlArray(this._map, this._key);
}

class MVCMapControlArrayList implements List<MVCArray> {
  GMap _map;

  MVCMapControlArrayList(this._map);

  operator[](key) => new MVCMapControlArray(_map, key);
} // TODO(serialize stuff??
