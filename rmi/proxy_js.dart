#library('proxyjs');

#import('dart:html');

class ProxyJs {
  int id;
  String prototypeName;
  static int _nextIdNum = 0;
//TODO(; register latlang and stuff in ititialize method)!!
  initialize(String prototypeName) {
    this.prototypeName = prototypeName;
    id = _nextIdNum++;
  }

  List<int> findHandles(List arguments) {
    List handles = [];
    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i] is ProxyJs) {
        handles.add(i);
        arguments[i] = arguments[i].id;
      }
    }
    return [arguments, handles];
  }

  // no prototypeName means global function not part of any class.
  // or pass in 'window'??? see http://pivotallabs.com/users/pjaros/blog/articles/1368-javascript-constructors-prototypes-and-the-new-keyword
  ProxyJs([String prototypeName = null, List args= const []]) {
    initialize(prototypeName);
    if (prototypeName != null) {
      injectSource("""
      ${prototypeName}_new = function(args) {
        return new ${prototypeName}(args);
      }
      var port = new ReceivePortSync();
      port.receive(function foo(listArgs) {
        // this was the same
        var handlesList = listArgs['handles'];
        for (var i = 0; i < handlesList.length; i++) {
          argsListIndex = handlesList[i];
          listArgs['args'][argsListIndex] = _scope.get(listArgs['args'][argsListIndex]);
        }
        var result = ${prototypeName}_new(listArgs['args']);
        return {'_id': _scope.allocate(result), 'result': result};
      });
      window.registerPort('${prototypeName}_new', port.toSendPort());
      """);
      var args_result = findHandles(args);
      var result = this.invoke(
          {'receiver': id, 'method': '${prototypeName}_new', 'args':
            args_result[0],
           'handles': args_result[1]});
    }
  }

  ProxyJs.staticCall([String prototypeName = null]) { 
    initialize(prototypeName);
  }

  /**
   * Private constructor, only used to update a dart refernce to a JS object
   * that already exists.
   */
  ProxyJs._update(this.id, this.prototypeName);

  Map<String, Object> invoke(Map argsList) {
    print(argsList['method']);
    SendPortSync port = window.lookupPort(argsList['method']);
    return port.callSync({'callingObject': id, 'args': argsList['args'],
        'handles': argsList['handles']});
  }

  noSuchMethod(String method_name, List args) {
    var args_result = findHandles(args);
    var result = this.invoke(
        {'receiver': id, 'method': method_name, 'args': args_result[0], 'handles':
          args_result[1]});
    if (result is Map && result.containsKey('id')) {
      return new ProxyJs._update(result['id'], prototypeName);
    } else {
      throw new NoSuchMethodException(this, method_name, args);
    }
  }
  
  // This is temp test code.
  injectSource(code) {
    final script = new ScriptElement();
    script.type = 'text/javascript';
    script.innerHTML = code;
    document.body.nodes.add(script);
  }
}
