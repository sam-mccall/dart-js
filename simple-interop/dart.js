simple = (function() {
  function installHandler(handler, callback) {
    addEventListener(
        handler,
        function(e) { return callback(JSON.parse(e.data)); },
        false);
  }

  var _callbacks = Object.create(null);
  var _callback_id = 0;

  // Type converters.
  function OBJ(obj) { return obj; }

  function CALLBACK(closure) {
    var id = ++_callback_id;
    _callbacks[id] = closure;
    return id;
  }

  // Helper to expose Dart callbacks into JS.
  function _mkCallback(id, parameter_converters) {
    return function() {
      var args = [];
      for (var i = 0; i < arguments.length; i++) {
        args.push(parameter_converters[i](arguments[i]));
      }
      // TODO: switch to CustomEvent.
      var event = document.createEvent('TextEvent');
      event.initTextEvent(
          'system/callback',
          false, false, window,
          JSON.stringify({id: id, args: args}));
      return JSON.parse(window.dispatchEvent(event));
    }
  }

  installHandler('system/eval', eval);
  installHandler('system/js-callback', function (data) {
    _callbacks[data.id].apply(null, data.args);
  });

  return {
    OBJ: OBJ,
    CALLBACK: CALLBACK,
    _mkCallback: _mkCallback,
  };
})();
