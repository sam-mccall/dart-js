window.addEventListener('load', function() {
  test('js-calculator');
  test('dart-calculator');
});

function test(name) {
  console.group(name);
  try {
    var calc = new rpc.Client(name).connect();
    assertEquals(20, calc.multiply(4, calc.add(2, 3)));
    calc.generate_pi(function(x) { console.log(x); });
    calc.generate_e().onItem(function(digit) { console.log(digit); });
    calc.open_the_pod_bay_doors_hal().onComplete(function(result, err) {
      if (err != null) console.error(err.message); else console.log("Result", result);
    });
    console.log('success!');
  } catch (e) {
    console.error(e, e.stack);
  } finally {
    console.groupEnd(name);
  }
}

function assertEquals(a, b) {
  if (a != b) throw new Error("Expected " + a + ", but got " + b);
}


