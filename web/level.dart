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

abstract class Level extends GameObject {
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
  Vector3 playerFacePosition(int position);
  int setPlayerPosition(int position) {
    _playerPosition = position % numOfFaces;
    return _playerPosition;
  }

  void setup(GraphicsContext gc) {
    var gl = gc.gl;
    _faces = [];
    var idx = 0;
    for (var face in vertices()) {
      _faces.add(new LevelFace(idx, face));
      idx++;
    }
    _faces.forEach((face) => face.setup(gl));

    _setupProgram(gc);
  }

  void _setupProgram(GraphicsContext gc) {
    _shader = gc.getShader('level');
    _uCameraTransform = _shader.getUniform('uCameraTransform');
    _uModelTransform = _shader.getUniform('uModelTransform');
    _uActive = _shader.getUniform('uActive');
    _aPosition = _shader.getAttribute('aPosition');
    _aUV = _shader.getAttribute('aTexCoord');
  }

  void update(double timeStep) {
  }

  void render(GraphicsContext gc, Float32List cameraTransform) {
    var gl = gc.gl;
    gl.useProgram(_shader._program);
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
  List<Vector3> _playerFacePositions;

  CylinderLevel() {
    _generateFaces();
  }

  @override
  int get numOfFaces => 16;

  @override
  List<List<double>> vertices() => _vertices;

  @override
  Vector3 playerFacePosition(int position) {
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
    _playerFacePositions = new List<Vector3>();
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

      // TODO: Seems to be wrong
      _playerFacePositions.add(new Vector3(middle(x, nextX), y, 0.0));

      x = nextX;
      y = nextY;
    }
  }
}
