
#import("dart:json");
#import("dart:isolate");
#import("dart:html");


class RPC {
  String _portName;
  Map<String, Function> _methods;
  
  RPC.Server(String portName, Map methods) {
    _portName = portName;
    var recvPort = new ReceivePortSync();
    recvPort.receive(receiveCallback);
    window.registerPort(portName, recvPort.toSendPort());
    _methods = methods;
  }
  
  RPC.Client(String portName) {
    _portName = portName;
    _methods = null;
    // Debugging stuff
    var port = window.lookupPort(portName);
    assert(port != null);
    var res = port.callSync({"method":"__index__", "args":[]});
    print(res);
  }

  apply(Function f, List args) {
    switch (args.length) {
      case 0: return f();
      case 1: return f(args[0]);
      case 2: return f(args[0], args[1]);
      case 3: return f(args[0], args[1], args[2]);
      default: throw("too many arguments!");
    }
  }

  receiveCallback(String msg) {
    String methodName = msg["method"];
    assert(methodName != null);
    List args = msg["args"];
    assert(args != null);
    var result;
    if (methodName == "__index__") {
      return {"value": _methods.getKeys()};
    }
    if (_methods[methodName] == null) {
      return {"exception":"unknown rpc request '$methodName'"};
    }
    print(msg);
    Function m = _methods[methodName];
    try {
      var r = apply(m, args);
      return {"value": r};
    } catch(var e) {
      return {"exception": e.toString() };
    }
  }
  
  send(String methodName, List args) {
    var port = window.lookupPort(_portName);
    assert(port != null);
    var msg = {"method": methodName, "args": args};
    print("sending: $msg");
    var res = port.callSync(msg);
    if (res["value"] != null) {
      return res["value"];
    } else if (res["exception"] != null) {
      print("received exception: ${res["exception"]}");
      throw res["exception"];
    } else {
      throw "Illegal rpc response format.";
    }
  }
  
  noSuchMethod(String methodName, List args) {
    return send(methodName, args);
  }
}


class CalcServer {
  RPC _rpc;
  
  CalcServer() {
    var calcMethods = {
      "multiply": (a,b) => a * b,
      "add":      (a,b) => a + b,
      "subtract": (a,b) => a - b,
      "divide":   (a,b) => a / b
    };
    _rpc = new RPC.Server("dart-calculator", calcMethods);
  }
}


main() {
  var jscalc= new RPC.Client("js-calculator");
  var sum = jscalc.add(10, 4);
  Expect.equals(14, sum);
  print("js-calculator result: $sum");
  try {
    var trash = jscalc.foo(100);
    Expect.fail("Error: failed to throw exception for non-existing method.");
  } catch (var e) {
  }

  var f = new CalcServer();
}