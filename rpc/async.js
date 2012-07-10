async = (function() {
  function Future() {
    this.listeners = [];
  }

  Future.prototype.onComplete = function(callback) {
    this.listeners.push(callback);
  };

  function Completer(future) {
    this.future = (future == null) ? new Future() : future;
  }

  Completer.prototype.complete = function(result, err) {
    this.future.listeners.forEach(function(callback) {
      try {
        callback(result, err);
      } catch (e) {
        console.log("Completion handler failed", e, e.stack);        
      }
    })
  };

  function Stream() {
    this.itemListeners = [];
    this.closeListeners = [];
  }

  Stream.prototype.onItem = function(callback) {
    this.itemListeners.push(callback);
  }

  Stream.prototype.onClose = function(callback) {
    this.closeListeners.push(callback);
  }

  function StreamSource(stream) {
    this.stream = (stream == null) ? new Stream() : stream;
  }

  StreamSource.prototype.emit = function(item) {
    this.stream.itemListeners.forEach(function(callback) {
      try {
        callback(item);
      } catch (e) {
        console.log("Stream handler failed", e, e.stack);        
      }
    })
  }

  StreamSource.prototype.close = function(item) {
    this.stream.closeListeners.forEach(function(callback) {
      try {
        callback(item);
      } catch (e) {
        console.log("Stream close handler failed", e, e.stack);        
      }
    })
  }

  return ({
    Future: Future,
    Completer: Completer,
    Stream: Stream,
    StreamSource: StreamSource,
  });
})();