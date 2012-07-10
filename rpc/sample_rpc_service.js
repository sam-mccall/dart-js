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
}).expose();
