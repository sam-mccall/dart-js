#library('js');

#import('dart:json');
#import('dart:html');

sendToJs(handler, data) {
  // TODO: switch to custom events.
  final event = document.$dom_createEvent('TextEvent');
  event.initTextEvent(handler, false, false, window, JSON.stringify(data));
  window.$dom_dispatchEvent(event);
}

evalInJs(code) {
  sendToJs('system/eval', code);
}

class _Callback {
  final id;
  final closure;
  final parameters;

  _Callback(this.closure, this.parameters) : id = _Callback._id++ {
    if (_callbacks === null) _callbacks = new Map<int, _Callback>();
    _callbacks[id] = this;
  }

  toString() => 'simple._mkCallback($id, $parameters)';

  _invoke(data) {
    assert(data.length == parameters.length);
    final args = [];
    for (int i = 0; i < data.length; i++) {
      args.add(parameters[i].converter(data[i]));
    }
    switch (data.length) {
      case 1: closure(args[0]); break;
      case 2: closure(args[0], args[1]); break;
      default: throw 'Unsupported number of arguments.';
    }
  }

  static invoke(e) {
    final data = JSON.parse(e.data);
    return JSON.stringify(_callbacks[data['id']]._invoke(data['args']));
  }

  static int _id = 0;
  static Map<int, _Callback> _callbacks;
}
callback(closure, parameters) => new _Callback(closure, parameters);

init() {
  window.$dom_addEventListener('system/callback', _Callback.invoke, false);
}

class _Parameter {
  final id;
  final converter;

  const _Parameter(this.id, this.converter);

  toString() => 'simple.$id';
}

_Parameter _obj;
get OBJ() {
  if (_obj === null) _obj = new _Parameter('OBJ', (x) => x);
  return _obj;
}
    
_Parameter _callback;
get CALLBACK() {
  if (_callback === null) _callback = new _Parameter('CALLBACK', (id) {
    // TODO: support other arities.
    return (x) => sendToJs('system/js-callback', {'id': id, 'args': [x]});
  });
  return _callback;
}
