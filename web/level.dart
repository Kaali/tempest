part of tempest;

class LevelFace {
  Float32List _faces;
  int _index;
  VertexUVBuffer _vertexUVBuffer;
  int _uvOffset;

  int get index => _index;

  LevelFace(int index, Float32List faces) {
    _index = index;
    _faces = faces;
  }

  void setup(WebGL.RenderingContext gl) {
    _setupBuffer(gl);
  }

  void _setupBuffer(WebGL.RenderingContext gl) {
    var indices = new List.generate((_faces.length / 5).toInt(), (idx) => idx);
    _vertexUVBuffer = new VertexUVBuffer(gl, _faces, indices, mode:WebGL.RenderingContext.TRIANGLE_STRIP);
  }

  void render(WebGL.RenderingContext gl, int aPosition, int aUV) {
    _vertexUVBuffer.bind(gl, aPosition, aUV);
    _vertexUVBuffer.draw(gl);
  }
}

abstract class Level implements GameObject {
  List<LevelFace> _faces;
  bool _loop;
  Vector3 _position;
  double _time;
  Shader _shader;
  WebGL.UniformLocation _uCameraTransform;
  WebGL.UniformLocation _uModelTransform;
  WebGL.UniformLocation _uActive;
  int _aPosition;
  int _aUV;
  int _roll;

  Level() {
    _position = new Vector3(0.0, 0.0, -3.0);
    _time = 0.0;
    _roll = 0;
  }

  List<Float32List> generateFaces();

  void setup(WebGL.RenderingContext gl) {
    _faces = [];
    int idx = 0;
    for (Float32List face in generateFaces()) {
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
        gl_FragColor = vec4(vActive, 1.0 * edge, 0.0, 1.0);
      } else {
        // Inner
        gl_FragColor = vec4(0.1, 0.2, 0.1, 1.0);
      }

      // fog test just for kicks
      float fogNear = 0.1;
      float fogFar = 2.8;
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
    _time += timeStep;
    _position = new Vector3(Math.sin(_time) * 0.8, 0.0, -3.0);
    _roll = (_time * 10.0).toInt() % 16;
  }

  void render(WebGL.RenderingContext gl, Float32List cameraTransform) {
    gl.useProgram(_shader.program);
    gl.uniformMatrix4fv(_uCameraTransform, false, cameraTransform);

    var modelTransform = new Matrix4.translation(_position);
    var modelTransformMatrix = new Float32List(16);
    modelTransform.copyIntoArray(modelTransformMatrix, 0);
    gl.uniformMatrix4fv(_uModelTransform, false, modelTransformMatrix);

    for (var face in _faces) {
      gl.uniform1i(_uActive, face.index == _roll ? 1 : 0);
      face.render(gl, _aPosition, _aUV);
    }
  }
}

class CylinderLevel extends Level {
  List<Float32List> generateFaces() {
    List<Float32List> faces = [];
    int sides = 16;
    double theta = 2.0 * Math.PI / sides;
    double c = Math.cos(theta);
    double s = Math.sin(theta);
    double radius = 1.0;
    double depth = 2.0;
    double x = radius;
    double y = 0.0;
    for (int i = 0; i < sides; ++i) {
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
      faces.add(new Float32List.fromList(vertices));

      x = nextX;
      y = nextY;
    }
    return faces;
  }
}