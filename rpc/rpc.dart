#library("rpc");
#import("dart:json");
//#import("dart:isolate", prefix: "isolate");
#import("dart:html");


class HandleTable {
  Map handles;
  HandleTable() {
    handles = new Map<String, Object>();
  }
  String nextId() {
    var id = (Math.random() * 1000000).toInt().toString();
    assert(!handles.containsKey(id));
    return id;
  }
  String registerObject(o) {
    var id = nextId();
    handles[id] = o;
    return id;
  }
  getObject(String id) {
    assert(handles.containsKey(id));
    return handles[id];
  }
  releaseObject(String id) {
    assert(handles.containsKey(id));
    handles.remove(id);
  }
}

class RemoteObject {
  String handleType;
  String id;
  String home;
  SendPortSync port;
  RPC rpc;
  
  RemoteObject(this.handleType, this.id, this.home, this.port, this.rpc) {
  }
  
  factory RemoteObject.fromJSON(Map json, RPC rpc) {
    assert(json["\$type"] == "handle");
    var handleType = json["handleType"];
    assert(handleType != null);
    var port = json["port"];
    if (handleType == 'function') {
      return new RemoteFunction(json["id"], json["home"], port, rpc);
    } else if (handleType == null) {
      return new RemoteObject(null, json["id"], json["home"], port, rpc);
    } else {
      throw "unsupported remote object type '$handleType'";
    }
  }

  Map serialize() {
    var serializedFunc = { "\$type": "handle",
             "handleType": handleType,
             "id": id,
             "port": port,
             "home": home };
    return serializedFunc;
  }
}

class RemoteFunction extends RemoteObject {
  RemoteFunction(String id, String home, SendPortSync port, RPC rpc)
    : super('function', id, home, port, rpc) {
  }
  
  String toString() =>
    "'RemoteFunction: {handleType: '$handleType', id: '$id'"
    ", home: '$home', port: '$port'}'";
  
  invoke(List args) {
    assert(port != null);
    assert(port is SendPortSync);
    return rpc.send(port, "__call__", [this, args]);
  }
}


class RPC {
  String _portName;
  String _homeId;
  ReceivePortSync _recvPort;
  Map<String, Function> _methods;
  HandleTable _handles;
    
  RPC.Server(String portName, Map methods) {
    _handles = new HandleTable();
    _portName = portName;
    _homeId = makeHomeId();
    _recvPort = new ReceivePortSync();
    _recvPort.receive(receiveCallback);
    window.registerPort(portName, _recvPort.toSendPort());
    _methods = methods;
  }
  
  RPC.Client(String portName) {
    _handles = new HandleTable();
    _portName = portName;
    _homeId = makeHomeId();
    _methods = null;
    _recvPort = new ReceivePortSync();
    _recvPort.receive(receiveCallback);
    // Debugging stuff. Check whether the server responds to the __index__
    // rpc call.
    var port = window.lookupPort(portName);
    assert(port != null);
    var res = port.callSync({"method":"__index__", "args":[]});
    debug(res);
  }

  String makeHomeId() => (Math.random() * 1000000).toInt().toString();

  SendPortSync mySendPort() {
    assert(_recvPort != null);
    return _recvPort.toSendPort();
  }

  serialize(obj) {
    if (obj is RemoteObject) {
      return obj.serialize();
    } else if (obj is Function) {
      var handleId = _handles.registerObject(obj);
      return { 
        "\$type": "handle",
        "handleType": "function",
        "id": handleId,
        "port": mySendPort(),
        "home": _homeId };
    } else if (obj is List) {
      var newList = new List(obj.length);
      for (int i = 0; i < obj.length; i++) {
        newList[i] = serialize(obj[i]);
      }
      return newList;
    } else if (obj is Map) {
      var newMap = new Map();
      obj.forEach((k, v) {
          newMap[serialize(k)] = serialize(v);
      });
      return newMap;
    } else {
      return obj;
    }
  }
  
  deserialize(obj) {
    if (obj is List) {
      for (int i = 0; i < obj.length; i++) {
        // We can be destructive, no need to copy.
        obj[i] = deserialize(obj[i]);
      }
    } else if ((obj is Map) && (obj["\$type"] == "handle")) {
      if (obj["home"] == _homeId) {
        assert(obj["id"] != null);
        obj = _handles.getObject(obj["id"]);
      } else {
        obj = new RemoteObject.fromJSON(obj, this);
      }
    }
    return obj;
  }

  apply(Function f, List args) {
    switch (args.length) {
      case 0: return f();
      case 1: return f(args[0]);
      case 2: return f(args[0], args[1]);
      case 3: return f(args[0], args[1], args[2]);
      default: throw "too many arguments!";
    }
  }

  receiveCallback(String msg) {
    debug("receiveCallback: $msg");
    String methodName = msg["method"];
    assert(methodName != null);
    List serializedArgs = msg["args"];
    assert(serializedArgs != null);
    List args = deserialize(serializedArgs);
    //debug("receiveCallback: deserialized args: $args");
    assert(args != null);
    if (methodName == "__index__") {
      return {"value": _methods.getKeys()};
    } else if (methodName == "__release__") {
      var id = args[0];
      var obj = _handles.getObject(id);
      //debug("request to release handle '$id' ($obj)");
      assert(id is String);
      assert(obj != null);
      _handles.releaseObject(id);
      return {"value": null};
    }
    Function m;
    if (methodName == "__call__") {
      assert(args.length == 2);
      m = args[0];     // First argument to rpc call is closure.
      args = args[1];  // Arguments to closure.
      //debug("request to call $m");
    } else {
      m = _methods[methodName];
      if (m == null) {
        return {"exception":"unknown rpc request '$methodName'"};
      }
    }
    assert(m is Function);
    try {
      var r = apply(m, args);
      r = serialize(r);
      return {"value": r};
    } catch(var e) {
      return {"exception": e.toString() };
    }
  }
  
  send(SendPortSync port, String methodName, List args) {
    debug("args before serialize: $args");
    var serializedArgs = serialize(args);
    var msg = {"method": methodName, "args": serializedArgs };
    debug("sending: $msg");
    var res = port.callSync(msg);
    debug("received: $res");
    if (res.containsKey("value")) {
      return deserialize(res["value"]);
    } else if (res["exception"] != null) {
      debug("received exception: ${res["exception"]}");
      throw res["exception"];
    } else {
      throw "Illegal rpc response format.";
    }
  }
  
  noSuchMethod(String methodName, List args) {
    debug(">>> noSuchMethod '$methodName' args: $args");
    var port = window.lookupPort(_portName);
    assert(port != null);
    return send(port, methodName, args);
  }
}

debug(message) {
  if (window.localStorage['debug_dart'] == 'true') print(message);
}

class CalcServer {
  RPC _rpc;
  
  generatePi(Map func_handle) {
    debug("generate_pi called with $func_handle");
    func_handle.invoke([4]);
    func_handle.invoke([2]);
    return null;
  }
  
  CalcServer() {
    var calcMethods = {
      "multiply": (a,b) => a * b,
      "add":      (a,b) => a + b,
      "subtract": (a,b) => a - b,
      "divide":   (a,b) => a / b,
      "generate_pi": (fh) => generatePi(fh)
    };
    _rpc = new RPC.Server("dart-calculator", calcMethods);
  }
}

testClient() {
  void handlePiDigit(digit) {
    debug("getting pi digit: $digit");
  }
  
  var jscalc= new RPC.Client("js-calculator");
  var sum = jscalc.add(10, 4);
  Expect.equals(14, sum);
  debug("js-calculator result: $sum");
  jscalc.generate_pi(handlePiDigit);
  try {
    var trash = jscalc.foo(100);
    Expect.fail("Error: failed to throw exception for non-existing method.");
  } catch (var e) {
  }
}

main() {
  testClient();
  var f = new CalcServer();
}
