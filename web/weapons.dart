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
    print(vertices.length);
    var indices = const <int>[0, 1, 2, 3];
    print(indices.length);
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

  Vector3 _position;
  Vector3 _velocity;
  double _lifetime;

  Bullet(Vector3 this._position, Vector3 this._velocity, {double lifetime: 4.0})
      : _lifetime = lifetime;


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
