window.addEventListener('load', function() {

var calc = new rpc.Client('calculator').connect();
//assertEquals(20, calc.multiply(4, calc.add(2, 3)));
assertEquals(20, calc.method('multiply')(4, calc.method('add')(2, 3)));
console.log('success!');

function assertEquals(a, b) {
  if (a != b) throw new Error("Expected " + a + ", but got " + b);
}

});
