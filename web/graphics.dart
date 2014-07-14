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
  List<WebGL.Texture> _boundTextures;

  WebGL.RenderingContext get gl => _gl;

  GraphicsContext(WebGL.RenderingContext this._gl, int this._width,
                  int this._height)
      : _shaders = new Map<String, Shader>(),
        _boundTextures = new List.filled(WebGL.TEXTURE31 - WebGL.TEXTURE0, null);

  //
  // General
  //
  void clear() {
    gl.viewport(0, 0, _width, _height);
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clearDepth(1.0);
    gl.clear(
        WebGL.RenderingContext.COLOR_BUFFER_BIT |
        WebGL.RenderingContext.DEPTH_BUFFER_BIT);
  }

  //
  // Textures
  //
  WebGL.Texture createRGBATexture(int width, int height) {
    var tex = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, tex);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, WebGL.CLAMP_TO_EDGE);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, WebGL.CLAMP_TO_EDGE);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
    gl.texImage2D(
        WebGL.TEXTURE_2D, 0, WebGL.RGBA, width, height, 0, WebGL.RGBA,
        WebGL.UNSIGNED_BYTE, null);
    return tex;
  }

  WebGL.Framebuffer createFBO(WebGL.Texture texture, int attachment) {
    var fbo = gl.createFramebuffer();
    withBindFramebuffer(fbo, (_) {
      gl.framebufferTexture2D(
          WebGL.FRAMEBUFFER, attachment, WebGL.TEXTURE_2D, texture, 0);
    });
    return fbo;
  }

  void withBindFramebuffer(WebGL.Framebuffer framebuffer,
                           void boundFn(GraphicsContext)) {
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, framebuffer);
    try {
      boundFn(this);
    } finally {
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
    }
  }

  void bindTexture(WebGL.Texture texture, int number) {
    gl.activeTexture(WebGL.TEXTURE0 + number);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
  }

  //
  // Shaders
  //
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

  void uniform1i(WebGL.UniformLocation uniform, int value) {
    gl.uniform1i(uniform, value);
  }

  void uniform1f(WebGL.UniformLocation uniform, num value) {
    gl.uniform1f(uniform, value);
  }
}
