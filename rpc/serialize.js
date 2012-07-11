//TODO(sammccall): handle cyclic structures

serialize = (function() {
  function Transform(test, apply) {
    this.test = test;
    this.apply = apply;
  }

  function Transforms() {
    this.items = [];
    var self = this;
    this.register(function(x) { return typeof x == 'object' && x != null; }, function(obj) {
      var result = {};
      for (var key in obj) {
        if (obj.hasOwnProperty(key)) result[key] = self.apply(obj[key]);
      }
      return result;
    });
    this.register(function(x) { return x instanceof Array; }, function(list) {
      var result = new Array(list.length);
      for (var i = 0; i < list.length; i++) {
        result[i] = self.apply(list[i]);
      }
      return result;
    });
  }

  Transforms.prototype.register = function(test, apply) {
    this.items.push(new Transform(test, apply));
  }

  Transforms.prototype.apply = function(object) {
    for (var i = this.items.length - 1; i >= 0; i--) {
      if (this.items[i].test(object)) return this.items[i].apply(object);
    }
    return object;
  }

  function Serializer() {
    Transforms.call(this);
    this.register(function(x) { return typeof x == 'undefined'; }, function(x) { return null; });
  }
  Serializer.prototype = Object.create(Transforms.prototype);

  function Deserializer() {
    Transforms.call(this);
  }
  Deserializer.prototype = Object.create(Transforms.prototype);

  return {
    Serializer: Serializer,
    Deserializer: Deserializer,
  };
})();