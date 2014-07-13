part of tempest;

class BulletPool {
  List<Bullet> _bullets;

  BulletPool(int count) : _bullets = new List<Bullet>() {
    var zero = new Vector3(0.0, 0.0, 0.0);
    for (var i = 0; i < count; ++i) {
      var bullet = new Bullet(zero, zero);
      bullet.destroyed = true;
      _bullets.add(bullet);
    }
  }

  Bullet get() {
    // TODO: Optimize lookup with free lists
    return _bullets.firstWhere((bullet) => bullet.destroyed, orElse: () => null);
  }
}

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
    _setupBuffer(gc.gl);
  }

  void _setupBuffer(WebGL.RenderingContext gl) {
    const size = 0.1;
    var vertices = const <double>[
      -size, -size, 0.0, 0.0, 0.0,
      size, -size, 0.0, 1.0, 0.0,
      size, size, 0.0, 1.0, 1.0,
      -size, size, 0.0, 0.0, 1.0,
    ];
    var indices = const <int>[0, 1, 2, 3];
    _vertexUvBuffer = new VertexUVBuffer(gl, vertices, indices,
        mode:WebGL.RenderingContext.TRIANGLE_FAN);
  }

  void render(GraphicsContext gc, Float32List cameraTransform) {
    var gl = gc.gl;
    gl.useProgram(_shader._program);
    gl.uniformMatrix4fv(_uCameraTransform, false, cameraTransform);

    var modelTransform = new Matrix4.translation(position);
    var modelTransformMatrix = new Float32List(16);
    modelTransform.copyIntoArray(modelTransformMatrix, 0);
    gl.uniformMatrix4fv(_uModelTransform, false, modelTransformMatrix);

    _vertexUvBuffer.bind(gl, _aPosition, _aUV);
    _vertexUvBuffer.draw(gl);
  }
}

class Bullet extends GameObject {
  static final BulletDrawable _bulletDrawable = new BulletDrawable();
  static final BulletPool _pool = new BulletPool(50);

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
