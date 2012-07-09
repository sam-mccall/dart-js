new rpc.Service('calculator', {
  add: function(x, y) { return x + y; },
  subtract: function(x, y) { return x - y; },
  multiply: function(x, y) { return x * y; },
  divide: function(x, y) { return x / y; },
}).expose();
