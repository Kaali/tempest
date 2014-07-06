part of tempest;

// Actions register to this, which runs from the update loop
class ActionManager {
  List<Action> _actions;
  List<Action> _registerQueue;
  List<Action> _unregisterQueue;

  ActionManager()
      : _actions = new List<Action>(),
        _registerQueue = new List<Action>(),
        _unregisterQueue = new List<Action>();

  void register(Action action) {
    _registerQueue.add(action);
  }

  void unregister(Action action) {
    _unregisterQueue.add(action);
  }

  void _handleRegistrations() {
    _actions.removeWhere(_unregisterQueue.contains);
    _registerQueue.where((a) => !_actions.contains(a)).forEach(_actions.add);
    _registerQueue.clear();
    _unregisterQueue.clear();
  }

  void update(double timeStep) {
    _handleRegistrations();
    _actions.forEach((action) => action.update(timeStep));
  }
}

typedef void ActionCallback();
typedef void ActionTick(double timeStep);

// Actions are owned by objects, registered to ActionManaget
// No weak refs? Manual dispose, maybe deregister on stop/cancel etc.
class Action {
  final ActionManager _actionManager;
  bool _isRunning;
  double _time;
  double length;
  ActionCallback _onStartCallback;
  ActionCallback _onStopCallback;
  ActionCallback _onResetCallback;
  ActionCallback _onCancelCallback;
  ActionTick _onTickCallback;

  Action(ActionManager this._actionManager)
      : _isRunning = false,
        _time = 0.0,
        length = -1.0;

  bool get isRunning => _isRunning;

  void start() {
    if (!_isRunning) {
      _register();
      _isRunning = true;
      if (_onStartCallback != null) _onStartCallback();
    }
  }

  void restart() {
    _time = 0.0;
    start();
  }

  void stop() {
    if (_isRunning) {
      _unregister();
      _isRunning = false;
      if (_onStopCallback != null) _onStopCallback();
    }
  }

  void reset() {
    _time = 0.0;
    if (_onResetCallback != null) _onResetCallback();
  }

  void cancel() {
    if (_isRunning) {
      _unregister();
      _isRunning = false;
      if (_onCancelCallback != null) _onCancelCallback();
    }
  }

  void update(double timeStep) {
    var doStop = false;
    if (_isRunning) {
      _time += timeStep;
      if (length != -1.0 && _time >= length) {
        _time = length;
        doStop = true;
      }
      if (_onTickCallback != null) _onTickCallback(_time);
      if (doStop) {
        stop();
      }
    }
  }

  void _register() {
    _actionManager.register(this);
  }

  void _unregister() {
    _actionManager.unregister(this);
  }

  void registerOnStart(ActionCallback callback) {
    _onStartCallback = callback;
  }

  void registerOnStop(ActionCallback callback) {
    _onStopCallback = callback;
  }

  void registerOnReset(ActionCallback callback) {
    _onResetCallback = callback;
  }

  void registerOnCancel(ActionCallback callback) {
    _onCancelCallback = callback;
  }

  void registerOnTick(ActionTick callback) {
    _onTickCallback = callback;
  }

}

typedef void MoveTick(Vector3 position);

class MoveAction {
  final Action _action;
  Vector3 _start;
  Vector3 _current;
  Vector3 _end;
  double _length;
  MoveTick _onMoveCallback;

  MoveAction(ActionManager actionManager)
      : _action = new Action(actionManager) {
    _action.registerOnTick(_onTick);
  }

  Vector3 get current => _current != null ? _current.clone() : null;
  bool get isRunning => _action.isRunning;

  void moveTo(Vector3 start, Vector3 end, double length) {
    _start = start;
    _end = end;
    _length = length;

    _action.length = length;
    _action.restart();
  }

  void registerOnMove(MoveTick callback) {
    _onMoveCallback = callback;
  }

  void _onTick(double time) {
    var percent = time / _length;
    _current = _start + (_end - _start).scale(percent);
    if (_onMoveCallback != null) _onMoveCallback(_current);
  }
}
