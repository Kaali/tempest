part of tempest;

class LevelFace {
  final List<double> _faces;
  final int _index;
  VertexUVBuffer _vertexUVBuffer;
  int _uvOffset;

  int get index => _index;

  LevelFace(int this._index, List<double> this._faces);

  void setup(WebGL.RenderingContext gl) {
    var indices = new List.generate((_faces.length / 5).toInt(), (idx) => idx);
    _vertexUVBuffer = new VertexUVBuffer(gl, _faces, indices,
        mode:WebGL.RenderingContext.TRIANGLE_STRIP);
  }

  void render(WebGL.RenderingContext gl, int aPosition, int aUV) {
    _vertexUVBuffer.bind(gl, aPosition, aUV);
    _vertexUVBuffer.draw(gl);
  }
}

abstract class Level implements GameObject {
  List<LevelFace> _faces;
  Vector3 _position;
  Shader _shader;
  WebGL.UniformLocation _uCameraTransform;
  WebGL.UniformLocation _uModelTransform;
  WebGL.UniformLocation _uActive;
  int _aPosition;
  int _aUV;
  int _playerPosition;

  Level() : _position = new Vector3(0.0, 0.0, -3.0);

  int get numOfFaces;
  List<List<double>> vertices();
  Vector2 playerFacePosition(int position);
  int setPlayerPosition(int position) {
    _playerPosition = position % numOfFaces;
    return _playerPosition;
  }

  void setup(WebGL.RenderingContext gl) {
    _faces = [];
    var idx = 0;
    for (var face in vertices()) {
      _faces.add(new LevelFace(idx, face));
      idx++;
    }
    _faces.forEach((face) => face.setup(gl));

    _setupProgram(gl);
  }

  void _setupProgram(WebGL.RenderingContext gl) {
    var vertexShader = '''
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    uniform mat4 uCameraTransform;
    uniform mat4 uModelTransform;
    uniform int uActive;

    varying vec2 vTexCoord;
    varying float vActive;

    void main(void) {
      vec4 pos = uCameraTransform * uModelTransform * vec4(aPosition, 1.0);
      gl_Position = pos;
      vTexCoord = aTexCoord;
      vActive = uActive == 1 ? 1.0 : 0.0;
    }
    ''';

    var fragmentShader = '''
    precision highp float;

    varying vec2 vTexCoord;
    varying float vActive;

    void main(void) {
      float width = 0.04;
      float edgeX = (vTexCoord.x < width || vTexCoord.x > 1.0 - width) ? 1.0 : 0.0;
      float edgeY = (vTexCoord.y < width || vTexCoord.y > 1.0 - width) ? 1.0 : 0.0;
      float edge = min(1.0, edgeX + edgeY);
      if (edge == 1.0) {
        // Edges
        gl_FragColor = vec4(0.2 * vActive, 0.3 * vActive, 1.0 * edge, 1.0);
      } else {
        // Inner
        gl_FragColor = vec4(0.025, 0.025, 0.05 + (0.2 * vActive), 1.0);
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
    _uActive = gl.getUniformLocation(_shader.program,'uActive');
    assert(_uActive != -1);
    _aPosition = gl.getAttribLocation(_shader.program, 'aPosition');
    assert(_aPosition != -1);
    _aUV = gl.getAttribLocation(_shader.program, 'aTexCoord');
    assert(_aUV != -1);
  }

  void update(double timeStep) {
  }

  void render(WebGL.RenderingContext gl, Float32List cameraTransform) {
    gl.useProgram(_shader.program);
    gl.uniformMatrix4fv(_uCameraTransform, false, cameraTransform);

    var modelTransform = new Matrix4.translation(_position);
    var modelTransformMatrix = new Float32List(16);
    modelTransform.copyIntoArray(modelTransformMatrix, 0);
    gl.uniformMatrix4fv(_uModelTransform, false, modelTransformMatrix);

    for (var face in _faces) {
      gl.uniform1i(_uActive, face.index == _playerPosition ? 1 : 0);
      face.render(gl, _aPosition, _aUV);
    }
  }
}

class CylinderLevel extends Level {
  List<List<double>> _vertices;
  List<Vector2> _playerFacePositions;

  CylinderLevel() {
    _generateFaces();
  }

  @override
  int get numOfFaces => 16;

  @override
  List<List<double>> vertices() => _vertices;

  @override
  Vector2 playerFacePosition(int position) {
    return _playerFacePositions[position];
  }

  void _generateFaces() {
    double middle(double a, double b) {
      if (a < b) {
        return a + (b - a) / 2.0;
      } else {
        return b + (a - b) / 2.0;
      }
    }
    _vertices = new List<List<double>>();
    _playerFacePositions = new List<Vector2>();
    var sides = numOfFaces;
    var theta = 2.0 * Math.PI / sides;
    var c = Math.cos(theta);
    var s = Math.sin(theta);
    var radius = 2.0;
    var depth = 2.0;
    var x = radius;
    var y = 0.0;
    for (var i = 0; i < sides; ++i) {
      var vertices = [
          x, y, 0.0, 0.0, 0.0,
          x, y, depth, 0.0, 1.0
      ];

      var nextX = c * x - s * y;
      var nextY = s * x + c * y;
      vertices.addAll([
          nextX, nextY, 0.0, 1.0, 0.0,
          nextX, nextY, depth, 1.0, 1.0
      ]);
      _vertices.add(vertices);
      _playerFacePositions.add(new Vector2(middle(x, nextX), y));

      x = nextX;
      y = nextY;
    }
  }
}
