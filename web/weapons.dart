part of tempest;

// TODO: Refactor as general drawable wireframe object
// TODO: Almost identical code is in Level
class BulletDrawable {
  bool _initialized;
  Shader _shader;
  Vector3 position;
  VertexUVBuffer _vertexUvBuffer;
  WebGL.UniformLocation _uCameraTransform;
  WebGL.UniformLocation _uModelTransform;
  int _aPosition;
  int _aUV;

  BulletDrawable() : _initialized = false;

  bool get initialized => _initialized;

  void setup(GraphicsContext gc) {
    _initialized = true;
    _shader = gc.getShader('weapon');
    _uCameraTransform = _shader.getUniform('uCameraTransform');
    _uModelTransform = _shader.getUniform('uModelTransform');
    _aPosition = _shader.getAttribute('aPosition');
    _aUV = _shader.getAttribute('aTexCoord');
    _vertexUvBuffer = new VertexUVBuffer.square(gc, size:0.1);
  }

  void render(GraphicsContext gc, Float32List cameraTransform) {
    gc.useShader(_shader);
    gc.uniformMatrix4fv(_uCameraTransform, false, cameraTransform);

    var modelTransform = new Matrix4.translation(position);
    var modelTransformMatrix = new Float32List(16);
    modelTransform.copyIntoArray(modelTransformMatrix, 0);
    gc.uniformMatrix4fv(_uModelTransform, false, modelTransformMatrix);

    _vertexUvBuffer.bind(gc, _aPosition, _aUV);
    _vertexUvBuffer.draw(gc);
  }
}

class Bullet extends GameObject {
  static final BulletDrawable _bulletDrawable = new BulletDrawable();
  static final ZERO = new Vector3(0.0, 0.0, 0.0);
  static final ObjectPool<Bullet> _pool =
      new ObjectPool<Bullet>(50, () => new Bullet(ZERO, ZERO),
          (b) => b.destroyed = true, (b) => b.destroyed);

  Vector3 _position;
  Vector3 _velocity;
  double _lifetime;

  Bullet(Vector3 this._position, Vector3 this._velocity, {double lifetime: 4.0})
      : _lifetime = lifetime;

  factory Bullet.pooled(Vector3 position, Vector3 velocity, {double lifetime: 4.0}) {
    var bullet = _pool.get();
    if (bullet != null) {
      bullet._position = position;
      bullet._velocity = velocity;
      bullet._lifetime = lifetime;
      bullet.destroyed = false;
    }
    return bullet;
  }

  void reset(Vector3 position, Vector3 velocity, double lifetime) {
    _position = position.clone();
    _velocity = velocity.clone();
    _lifetime = lifetime;
    destroyed = false;
  }

  @override
  void setup(GraphicsContext gc) {
    if (!_bulletDrawable.initialized) _bulletDrawable.setup(gc);
  }

  @override
  void update(double timeStep) {
    _position.addScaled(_velocity, timeStep);
    _lifetime -= timeStep;
    if (_lifetime <= 0.0) {
      destroyed = true;
    }
  }

  @override
  void render(GraphicsContext gc, Float32List cameraTransform) {
    // TODO: Fix setup system
    setup(gc);
    _bulletDrawable.position = _position;
    _bulletDrawable.render(gc, cameraTransform);
  }

}
