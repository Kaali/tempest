part of tempest;

// Manage shaders and drawables etc.
// I want to share managed objects

// All drawing and context changes should go trough here
// How to access objects? String or object handles?
class GraphicsContext {
  final WebGL.RenderingContext _gl;
  int _width;
  int _height;
  Shader _currentShader;
  Map<String, Shader> _shaders;

  WebGL.RenderingContext get gl => _gl;

  GraphicsContext(WebGL.RenderingContext this._gl, int this._width,
                  int this._height)
      : _shaders = new Map<String, Shader>();

  void clear() {
    gl.viewport(0, 0, _width, _height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clearDepth(1.0);
    gl.clear(
        WebGL.RenderingContext.COLOR_BUFFER_BIT |
        WebGL.RenderingContext.DEPTH_BUFFER_BIT);
  }

  Shader createShader(String name, String vertexShaderSource,
                      String fragmentShaderSource, List<String> uniforms,
                      List<String> attributes) {
    assert(!_shaders.containsKey(name));
    var shader = new Shader(_gl, vertexShaderSource, fragmentShaderSource,
        uniforms, attributes);
    assert(shader.isValid);
    _shaders[name] = shader;
  }

  Shader getShader(String name) {
    var shader = _shaders[name];
    assert(shader != null);
    return shader;
  }

  void useShader(Shader shader) {
    if (_currentShader != shader) {
      _gl.useProgram(shader._program);
      _currentShader = shader;
    }
  }

  void useShaderName(String shaderName) => useShader(getShader(shaderName));
}
