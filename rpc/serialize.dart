#library('serialize');

class _Transform {
  final Function test;
  final Function apply;
  _Transform(this.test, this.apply);
}

class Transforms {
  final List<_Transform> items;
  Transforms() : items = [] {
    register((x) => x is Map, function(map) {
      final result = new Map();
      for (final key in map.getKeys()) result[key] = this.apply(map[key]);
      return result;
    });
    register((x) => x is List, function(list) {
      final result = new List();
      for (final item in list) result.add(this.apply(item));
      return result;
    });
  }

  register(bool test(obj), Object apply(obj)) {
    items.add(new _Transform(test, apply));
  }

  //TODO(sammccall): handle cyclic structures
  Object apply(obj) {
    for (int i = items.length - 1; i >= 0; i--) {
      if (items[i].test(obj)) return items[i].apply(obj);
    }
    return obj;
  }
}

class Serializer extends Transforms {}
class Deserializer extends Transforms {}
