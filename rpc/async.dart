#library('async');

class Stream<T> {
  final List<Function> _itemListeners;  
  final List<Function> _closeListeners;

  Stream() : _itemListeners = [], _closeListeners = [];

  onItem(listener(T item)) {
    _itemListeners.add(listener);
  }

  onClose(listener()) {
    _closeListeners.add(listener);
  }
}

class StreamSource<T> {
  final Stream<T> stream;

  StreamSource() : stream = new Stream<T>();

  emit(T obj) {
    for (final listener in stream._itemListeners) {
      try {
        listener(obj);
      } catch (final e) {
        print("Stream listener threw exception: $e");
      }
    }
  }

  close() {
    for (final listener in stream._closeListeners) {
      try {
        listener();
      } catch (final e) {
        print("Stream close listener threw exception: $e");
      }
    }
  }
}
