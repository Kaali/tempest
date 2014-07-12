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
  WebGL.UniformLocation _uActive;
  int _aPosition;
  int _aUV;

  BulletDrawable() : _initialized = false;

  bool get initialized => _initialized;

  void setup(WebGL.RenderingContext gl) {
    _initialized = true;
    _setupShader(gl);
    _setupBuffer(gl);
  }

  void _setupShader(WebGL.RenderingContext gl) {
    // TODO: Need to share shaders
    var vertexShader = '''
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    uniform mat4 uCameraTransform;
    uniform mat4 uModelTransform;

    varying vec2 vTexCoord;

    void main(void) {
      vec4 pos = uCameraTransform * uModelTransform * vec4(aPosition, 1.0);
      gl_Position = pos;
      vTexCoord = aTexCoord;
    }
    ''';

    var fragmentShader = '''
    precision highp float;

    varying vec2 vTexCoord;

    void main(void) {
      float width = 0.04;
      float edgeX = (vTexCoord.x < width || vTexCoord.x > 1.0 - width) ? 1.0 : 0.0;
      float edgeY = (vTexCoord.y < width || vTexCoord.y > 1.0 - width) ? 1.0 : 0.0;
      float edge = min(1.0, edgeX + edgeY);
      if (edge == 1.0) {
        // Edges
        gl_FragColor = vec4(0.2, 0.3, 1.0 * edge, 1.0);
      } else {
        // Inner
        gl_FragColor = vec4(0.025, 0.025, 0.05, 1.0);
      }

      // fog test just for kicks
      float fogNear = 0.1;
      float fogFar = 4.0;
      float depth = gl_FragCoord.z / gl_FragCoord.w;
      float fog = smoothstep(fogNear, fogFar, depth);
      gl_FragColor = mix(gl_FragColor, vec4(0.0, 0.0, 0.0, gl_FragColor.w), fog);
    }
    ''';
    _shader = new Shader(vertexShader, fragmentShader);
    _shader.compile(gl);
    _shader.link(gl);

    _uCameraTransform = gl.getUniformLocation(_shader.program,'uCameraTransform');
    assert(_uCameraTransform != -1);
    _uModelTransform = gl.getUniformLocation(_shader.program,'uModelTransform');
    assert(_uModelTransform != -1);
    _aPosition = gl.getAttribLocation(_shader.program, 'aPosition');
    assert(_aPosition != -1);
    _aUV = gl.getAttribLocation(_shader.program, 'aTexCoord');
    assert(_aUV != -1);
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

  void render(WebGL.RenderingContext gl, Float32List cameraTransform) {
    gl.useProgram(_shader.program);
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
  void setup(WebGL.RenderingContext gl) {
    if (!_bulletDrawable.initialized) _bulletDrawable.setup(gl);
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
  void render(WebGL.RenderingContext gl, Float32List cameraTransform) {
    // TODO: Fix setup system
    setup(gl);
    _bulletDrawable.position = _position;
    _bulletDrawable.render(gl, cameraTransform);
  }

}
