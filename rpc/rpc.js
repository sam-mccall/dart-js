rpc = (function() {
  function Handles() {
    this.handles = {};
    this.nextId = 0;
  }

  Handles.prototype.allocate = function(object) {
    var id = (this.nextId++).toString();
    this.handles[id] = object;
    return id;
  }

  Handles.prototype.get = function(key) {
    if (!this.handles.hasOwnProperty(key)) throw new Error("Non-existent handle accessed: " + key);
    return this.handles[key];
  }

  Handles.prototype.release = function(key) {
    if (!this.handles.hasOwnProperty(key)) throw new Error("Non-existent handle freed: " + key);
    delete this.handles[key];
  }

  function Handle(home, id, endpoint, port) {
    this.home = home; // TODO(sammccall): just use port for this, once they can be compared
    this.id = id;
    this.endpoint = endpoint;
    this.port = port;
  }
  Handle.prototype.release = function() {
    invoke(this.endpoint, this.port, '__release__', this.id);
  };

  function FunctionHandle(home, id, endpoint, port) {
    Handle.call(this, home, id, endpoint, port);
  }
  FunctionHandle.prototype = Object.create(Handle.prototype);
  FunctionHandle.prototype.invoke = function() {
    return invoke(this.endpoint, this.port, '__call__', [this, Array.prototype.slice.call(arguments)]);
  };

  function Endpoint(name, methods) {
    this.id = generateId();
    this.name = name;
    this.methods = methods;
    this.serializer = new serialize.Serializer();
    this.deserializer = new serialize.Deserializer();
    this.receive = new ReceivePortSync();
    this.handles = new Handles();
    var endpoint = this;
    this.receive.receive(function(data) {
      try {
        var args = endpoint.deserializer.apply(data.args);
        var result = invokeHandler(endpoint, data.method, args);
        return {value: endpoint.serializer.apply(result)};
      } catch (e) {
        return {exception: e.toString()};
      }
    });
    this.serializer.register(function(x) { return x instanceof Function; }, function(func) {
      var id = endpoint.handles.allocate(func);
      return ({
        $type: 'handle',
        callback: true,
        id: id,
        home: endpoint.id,
        port: endpoint.receive.toSendPort(),
      });
    });
    this.serializer.register(function(x) { return x instanceof Handle; }, function(handle) {
      return ({
        $type: 'handle',
        callback: (handle instanceof FunctionHandle),
        id: handle.id,
        home: handle.home,
        port: handle.port,
      })
    });
    function typed(name) {
      return function(obj) { return (typeof obj == 'object') && (obj != null) && (obj.$type == name); };
    }
    this.deserializer.register(typed('handle'), function(obj) {
      if (obj.home == endpoint.id) return endpoint.handles.get(obj.id);
      return new (obj.callback ? FunctionHandle : Handle)(obj.home, obj.id, endpoint, obj.port);
    });
  }

  function Service(name, methodTable) {
    Endpoint.call(this, name, methodTable);
  }
  Service.prototype = Object.create(Endpoint.prototype);

  function invokeHandler(endpoint, name, args) {
    if (name == '__index__') return Object.keys(endpoint.methods);
    if (name == '__call__') return args[0].apply(null, args[1]);
    if (name == '__release__') return endpoint.handles.release(args[0]);
    if (endpoint.methods.hasOwnProperty(name)) return endpoint.methods[name].apply(null, args);
    throw new Error("No such method " + endpoint.name + "." + name);
  }

  Service.prototype.expose = function(name) {
    if (name == null) name = this.name;
    window.registerPort(name, this.receive.toSendPort());
  };

  function Client(name) {
    Endpoint.call(this, name, {});
    this.send = null;
  }

  function invoke(endpoint, port, method, args) {
    var args = endpoint.serializer.apply(args);
    var result = port.callSync({method:method, args:args, reply:endpoint.receive.toSendPort()});
    if (result.hasOwnProperty('exception')) throw new Error(result.exception);
    return endpoint.deserializer.apply(result.value);
  }

  Client.prototype.method = function(method) {
    var client = this;
    return function() {
      if (client.send == null) throw new Error("Not connected!");
      return invoke(client, client.send, method, Array.prototype.slice.call(arguments));
    }
  };

  Client.prototype.connect = function(name) {
    if (name == null) name = this.name;
    this.send = window.lookupPort(name);
    try {
      var methods = invoke(this, this.send, '__index__', []);
      for (var i = 0; i < methods.length; i++) {
        var method = methods[i];
        if (method in this) continue;
        this[method] = this.method(method);
      }
    } catch (e) {
      console.error("Failed to call __index__", e, e.stack);
    }
    return this;
  };

  function generateId() {
    return Math.floor(Math.random() * 1000000000).toString();
  }

  return {
    Service: Service,
    Client: Client,
  };
})();