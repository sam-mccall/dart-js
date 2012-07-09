rpc = (function() {
  function Service(name, methodTable) {
    var service = this;
    this.name = name;
    this.methods = methodTable;
    this.receive = new ReceivePortSync();
    this.receive.receive(function (data) {
      try {
        return {value: getMethod(service, data.method).apply(null, data.args)};
      } catch (e) {
        return {exception: e.toString()};
      }
    });
  }

  function getMethod(service, name) {
    if (name == '__index__') return function() { return Object.keys(service.methods); }
    if (service.methods.hasOwnProperty(name)) return service.methods[name];
    throw new Error("No such method " + service.name + "." + name);
  }

  Service.prototype.expose = function(name) {
    if (name == null) name = this.name;
    window.registerPort(name, this.receive.toSendPort());
  };

  function Client(name) {
    this.name = name;
    this.send = null;
  }

  Client.prototype.method = function(method) {
    var service = this;
    return function() {
      if (service.send == null) throw new Error("Not connected!");
      var args = Array.prototype.slice.call(arguments);
      var result = service.send.callSync({method:method, args:args});
      if (result.hasOwnProperty('error')) throw new Error(result.error);
      return result.value;
    }
  };

  Client.prototype.connect = function(name) {
    if (name == null) name = this.name;
    this.send = window.lookupPort(name);
    try {
      var methods = this.method('__index__')();
      for (var i = 0; i < methods.length; i++) {
        var method = methods[i];
        if (method in this) continue;
        this[method] = this.method(method);
      }
    } catch (e) {
      console.error("Failed to call __index__", e);
    }
    return this;
  };

  return {
    Service: Service,
    Client: Client,
  };
})();