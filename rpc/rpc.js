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

  function Handle(home, id, endpoint, port, type) {
    this.home = home; // TODO(sammccall): just use port for this, once they can be compared
    this.id = id;
    this.endpoint = endpoint;
    this.port = port;
    this.handleType = type;
  }
  Handle.prototype.handleType = null;
  Handle.prototype.release = function() {
    invoke(this.endpoint, this.port, '__release__', [this.id]);
  };

  function RemoteFunction(home, id, endpoint, port) {
    function result() {
      return invoke(result.handle.endpoint, result.handle.port,
          '__call__', [result, Array.prototype.slice.call(arguments)]);
    }
    result.handle = new Handle(home, id, endpoint, port, 'function');
    result.release = function() { result.handle.release(); };
    return result;
  }

  function RemoteStream(home, id, endpoint, port) {
    async.Stream.call(this);
    this.handle = new Handle(home, id, endpoint, port, 'stream');
    this.registered = false;
  }
  RemoteStream.prototype = Object.create(async.Stream.prototype);
  RemoteStream.prototype.onItem = function(callback) {
    registerRemoteStream(this);
    async.Stream.prototype.onItem.call(this, callback);
  };
  RemoteStream.prototype.onClose = function(callback) {
    registerRemoteStream(this);
    async.Stream.prototype.onClose.call(this, callback);
  };
  function registerRemoteStream(stream) {
    if (stream.registered) return;
    var completer = new async.StreamSource(stream);
    invoke(stream.handle.endpoint, stream.handle.port, '__subscribe__', [stream.handle, function(result) {
      (result.closed) ? completer.close() : completer.emit(result.value);
    }]);
    stream.registered = true;
  }

  function RemoteFuture(home, id, endpoint, port) {
    async.Future.call(this);
    this.handle = new Handle(home, id, endpoint, port, 'future');
    this.registered = false;
  }
  RemoteFuture.prototype = Object.create(async.Future.prototype);
  RemoteFuture.prototype.onComplete = function(callback) {
    registerRemoteFuture(this);
    async.Future.prototype.onComplete.call(this, callback);
  };
  function registerRemoteFuture(future) {
    if (future.registered) return;
    var completer = new async.Completer(future);
    invoke(future.handle.endpoint, future.handle.port, '__subscribe__', [future.handle, function(result) {
      var err = result.hasOwnProperty('exception');
      completer.complete(
          err ? undefined : result.value,
          err ? new Error(result.exception) : undefined);
    }]);
    future.registered = true;
  }

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
      debug(endpoint, "received", data);
      var ret;
      try {
        var args = endpoint.deserializer.apply(data.args);
        debug(endpoint, "invoking", data.method, args);
        var result = invokeHandler(endpoint, data.method, args);
        debug(endpoint, data.method, "returned", result);
        ret = {value: endpoint.serializer.apply(result)};
      } catch (e) {
        debug(endpoint, data.method, "threw", e, e.stack);
        ret = {exception: e.toString()};
      }
      debug(endpoint, "returning", ret);
      return ret;
    });
    function serializeHandle(handle) {
      if (!(handle instanceof Handle)) throw new Error("Not a handle");
      return ({
        $type: 'handle',
        id: handle.id,
        handleType: handle.handleType,
        home: handle.home,
        port: handle.port,
      })
    }
    this.serializer.register(function(x) { return x instanceof Function; }, function(func) {
      return serializeHandle(func.hasOwnProperty('handle') ? func.handle : endpoint.handle(func));
    });
    this.serializer.register(function(x) { return x instanceof Handle; }, serializeHandle);
    this.serializer.register(function(x) { return x instanceof async.Stream; }, function(stream) {
      if (stream instanceof RemoteStream) return serializeHandle(stream.handle);
      var handle = endpoint.handle(stream);
      stream.onClose(function() {
        endpoint.handles.release(handle.id);
      });
      return serializeHandle(handle);
    });
    this.serializer.register(function(x) { return x instanceof async.Future; }, function(future) {
      if (future instanceof RemoteFuture) return serializeHandle(future.handle);
      var handle = endpoint.handle(future);
      future.onComplete(function() {
        endpoint.handles.release(handle.id);
      });
      return serializeHandle(handle);
    });
    function typed(name) {
      return function(obj) { return (typeof obj == 'object') && (obj != null) && (obj.$type == name); };
    }
    this.deserializer.register(typed('handle'), function(obj) {
      if (obj.home == endpoint.id) return endpoint.handles.get(obj.id);
      var type = getHandleTypeByName(obj.handleType);
      return new type(obj.home, obj.id, endpoint, obj.port);
    });
  }

  function getHandleTypeByName(name) {
    return (name == 'stream') ? RemoteStream
        : (name == 'future') ? RemoteFuture
        : (name == 'function') ? RemoteFunction
        : Handle;
  }

  function getHandleType(obj) {
    return (obj instanceof async.Stream) ? 'stream'
        : (obj instanceof async.Future) ? 'future'
        : (obj instanceof Function) ? 'function'
        : null;
  }

  Endpoint.prototype.handle = function(object) {
    var id = this.handles.allocate(object);
    var type = getHandleType(object);
    return new Handle(this.id, id, this, this.receive.toSendPort(), type);
  }

  function Service(name, methodTable) {
    Endpoint.call(this, name, methodTable);
  }
  Service.prototype = Object.create(Endpoint.prototype);

  function invokeHandler(endpoint, name, args) {
    if (name == '__index__') return Object.keys(endpoint.methods);
    if (name == '__call__') return args[0].apply(null, args[1]);
    if (name == '__release__') return endpoint.handles.release(args[0]);
    if (name == '__subscribe__') {
      var target = args[0];
      var callback = args[1];
      if (target instanceof async.Stream) {
        target.onItem(function(x) { callback({value:x}); });
        target.onClose(function() { callback({closed:true}); callback.release(); });
      } else if (target instanceof async.Future) {
        target.onComplete(function(x, err) { 
          callback((err == null) ? {value:x} : {exception:err.toString()});
          callback.release();
        });
      } else {
        throw new Error("Tried to subscribe to something not a Stream or a Future");
      }
      return null;
    }
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
  Client.prototype = Object.create(Endpoint.prototype);

  function invoke(endpoint, port, method, args) {
    var args = endpoint.serializer.apply(args);
    var result = port.callSync({method:method, args:args});
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

  function debug() {
    var args = Array.prototype.slice.call(arguments);
    if (window.localStorage['debug_js'] == 'true') console.log.apply(console, args);
  }

  return {
    Service: Service,
    Client: Client,
    Handle: Handle,
    RemoteFunction: RemoteFunction,
  };
})();