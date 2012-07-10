new rpc.Service('js-calculator', {
  add: function(x, y) { return x + y; },
  subtract: function(x, y) { return x - y; },
  multiply: function(x, y) { return x * y; },
  divide: function(x, y) { return x / y; },
  generate_pi: function(callback) {
    [3,1,4,1,5].forEach(function(d, i) {
      setTimeout(function() { callback.invoke(d); }, 100 * i);
    });
    setTimeout(function() { callback.release(); }, 1000);
  },
  generate_e: function() {
    var source = new async.StreamSource();
    setTimeout(function() {
      source.emit(2);
      source.emit(7);
      source.emit(1);
      source.emit(8);
      source.emit(3);
      source.close();
    }, 0);
    return source.stream;
  },
  open_the_pod_bay_doors_hal: function() {
    var completer = new async.Completer();
    setTimeout(function() {
      completer.complete(null, new Error("I'm sorry Dave, I'm afraid I can't do that."));
    }, 1000);
    return completer.future;
  },
}).expose();
