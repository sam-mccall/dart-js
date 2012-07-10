#library('proxyjs');

class ProxyJs {
  int _id;
  String prototypeName;
  static int _nextIdNum = 0;
//TODO(; register latlang and stuff in ititialize method)!!
  initialize(String prototypeName, List args) {
    this.prototypeName = prototypeName;
    _id = _nextIdNum++;
  }
  // no prototypeName means global function not part of any class.
  // or pass in 'window'??? see http://pivotallabs.com/users/pjaros/blog/articles/1368-javascript-constructors-prototypes-and-the-new-keyword
  ProxyJs([String prototypeName = null, List args]) {
    initialize(prototypeName, args);
    injectSource("""
    function ${prototypeName}_new(args) {
      return new ${prototypeName}(args);
    }
    """);
    var result = this.invoke(
        {'receiver': _id, 'method': '${prototypeName}_new', 'args': args});
  }

  ProxyJs.staticCall([String prototypeName = null]) { 
    initialize(prototypeName, []);
  }

  /**
   * Private constructor, only used to update a dart refernce to a JS object
   * that already exists.
   */
  ProxyJs._update(this._id, this.prototypeName);

  Map<String, Object> invoke(Map argsList) {
    SendPortSync port = window.lookupPort(argsList['method']);
    return port.callSync(argsList['args']);
  }

  noSuchMethod(String method_name, List args) {
    var result = this.invoke(
        {'receiver': _id, 'method': method_name, 'args': args});
    if (result is Map && result.containsKey('_id')) {
      return new ProxyJs._update(result['_id'], prototypeName);
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
