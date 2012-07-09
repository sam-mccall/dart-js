new rpc.Service('js-calculator', {
  add: function(x, y) { return x + y; },
  subtract: function(x, y) { return x - y; },
  multiply: function(x, y) { return x * y; },
  divide: function(x, y) { return x / y; },
  generate_pi: function(callback) {
    digits = [3,1,4,1,5];
    for (var i = 0; i < digits.length; i++) {
      setTimeout(function() { callback(digits[i]); }, 100 * i);
    }
  }
}).expose();
