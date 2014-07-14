part of tempest;

typedef T Init<T>();
typedef void Destroy<T>(T);
typedef bool IsDestroyed<T>(T);

class ObjectPool<T> {
  List<T> _objects;
  Init<T> _init;
  Destroy<T> _destroy;
  IsDestroyed<T> _isDestroyed;

  ObjectPool(int count, Init<T> this._init, Destroy<T> this._destroy,
             IsDestroyed<T> this._isDestroyed)
  : _objects = <T>[] {
    for (var i = 0; i < count ; ++i) {
      var object = _init();
      _destroy(object);
      _objects.add(object);
    }
  }

  T get() {
    return _objects.firstWhere(_isDestroyed, orElse: () => null);
  }
}

