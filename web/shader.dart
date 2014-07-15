part of tempest;

class Shader {
  final String _vertexShaderSource;
  final String _fragmentShaderSource;
  WebGL.Shader _vertexShader;
  WebGL.Shader _fragmentShader;
  WebGL.Program _program;
  Map<String, WebGL.UniformLocation> _uniforms;
  Map<String, int> _attributes;
  bool isValid;

  WebGL.Program get program => _program;

  Shader(WebGL.RenderingContext gl, this._vertexShaderSource,
         this._fragmentShaderSource, List<String> uniforms,
         List<String> attributes)
      : _uniforms = new Map<String, WebGL.UniformLocation>(),
        _attributes = new Map<String, int>(),
        isValid = false {
    if (_compile(gl)) {
      if (_link(gl)) {
        _setupProgram(gl, uniforms, attributes);
        isValid = true;
      }
    }
  }

  WebGL.UniformLocation getUniform(String name) => _uniforms[name];
  int getAttribute(String name) => _attributes[name];

  bool _compile(WebGL.RenderingContext gl) {
    _vertexShader = gl.createShader(WebGL.RenderingContext.VERTEX_SHADER);
    gl.shaderSource(_vertexShader, _vertexShaderSource);
    gl.compileShader(_vertexShader);
    if (!gl.getShaderParameter(_vertexShader, WebGL.COMPILE_STATUS)) {
      print(gl.getShaderInfoLog(_vertexShader));
      return false;
    }

    _fragmentShader = gl.createShader(WebGL.RenderingContext.FRAGMENT_SHADER);
    gl.shaderSource(_fragmentShader, _fragmentShaderSource);
    gl.compileShader(_fragmentShader);
    if (!gl.getShaderParameter(_fragmentShader, WebGL.COMPILE_STATUS)) {
      print(gl.getShaderInfoLog(_fragmentShader));
      return false;
    }

    return true;
  }

  bool _link(WebGL.RenderingContext gl) {
    assert(_program == null);
    assert(_vertexShader != null);
    assert(_fragmentShader != null);

    _program = gl.createProgram();
    gl.attachShader(_program, _vertexShader);
    gl.attachShader(_program, _fragmentShader);
    gl.linkProgram(_program);
    if (!gl.getProgramParameter(_program, WebGL.LINK_STATUS)) {
      print(gl.getProgramInfoLog(_program));
      return false;
    }
    return true;
  }

  void _setupProgram(WebGL.RenderingContext gl, List<String> uniforms,
                     List<String> attributes) {
    uniforms.forEach((name) {
      _uniforms[name] = gl.getUniformLocation(_program, name);
      assert(_uniforms[name] != null);
    });
    attributes.forEach((name) {
      _attributes[name] = gl.getAttribLocation(_program, name);
      assert(_attributes[name] != null);
    });
  }
}
