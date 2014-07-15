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
    gl.enable(WebGL.DEPTH_TEST);
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

  WebGL.Renderbuffer createRenderbuffer(int width, int height,
                                        int internalFormat) {
    var rb = gl.createRenderbuffer();
    withBindRenderbuffer(rb, (_) {
      gl.renderbufferStorage(WebGL.RENDERBUFFER, internalFormat, width, height);
    });
    return rb;
  }

  void attachFramebufferRenderbuffer(WebGL.Framebuffer fb, WebGL.Renderbuffer rb,
                         int attachment) {
    assert(rb != null);
    assert(fb != null);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, fb);
    gl.bindRenderbuffer(WebGL.RENDERBUFFER, rb);
    gl.framebufferRenderbuffer(WebGL.FRAMEBUFFER, attachment,
        WebGL.RENDERBUFFER, rb);
    gl.bindRenderbuffer(WebGL.RENDERBUFFER, null);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  void withBindRenderbuffer(WebGL.Renderbuffer rb,
                            void boundFn(GraphicsContext)) {
    gl.bindRenderbuffer(WebGL.RENDERBUFFER, rb);
    try {
      boundFn(this);
    } finally {
      gl.bindRenderbuffer(WebGL.RENDERBUFFER, null);
    }
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

  void uniform1f(WebGL.UniformLocation location, num x) => gl.uniform1f(location, x);

  void uniform1fv(WebGL.UniformLocation location, Float32List v) => gl.uniform1fv(location, v);

  void uniform1i(WebGL.UniformLocation location, int x) => gl.uniform1i(location, x);

  void uniform1iv(WebGL.UniformLocation location, Int32List v) => gl.uniform1iv(location, v);

  void uniform2f(WebGL.UniformLocation location, num x, num y) => gl.uniform2f(location, x, y);

  void uniform2fv(WebGL.UniformLocation location, Float32List v) => gl.uniform2fv(location, v);

  void uniform2i(WebGL.UniformLocation location, int x, int y) => gl.uniform2i(location, x, y);

  void uniform2iv(WebGL.UniformLocation location, Int32List v) => gl.uniform2iv(location, v);

  void uniform3f(WebGL.UniformLocation location, num x, num y, num z) => gl.uniform3f(location, x, y, z);

  void uniform3fv(WebGL.UniformLocation location, Float32List v) => gl.uniform3fv(location, v);

  void uniform3i(WebGL.UniformLocation location, int x, int y, int z) => gl.uniform3i(location, x, y, z);

  void uniform3iv(WebGL.UniformLocation location, Int32List v) => gl.uniform3iv(location, v);

  void uniform4f(WebGL.UniformLocation location, num x, num y, num z, num w) => gl.uniform4f(location, x, y, z, w);

  void uniform4fv(WebGL.UniformLocation location, Float32List v) => gl.uniform4fv(location, v);

  void uniform4i(WebGL.UniformLocation location, int x, int y, int z, int w) => gl.uniform4i(location, x, y, z, w);

  void uniform4iv(WebGL.UniformLocation location, Int32List v) => gl.uniform4iv(location, v);

  void uniformMatrix2fv(WebGL.UniformLocation location, bool transpose, Float32List array) => gl.uniformMatrix2fv(location, transpose, array);

  void uniformMatrix3fv(WebGL.UniformLocation location, bool transpose, Float32List array) => gl.uniformMatrix3fv(location, transpose, array);

  void uniformMatrix4fv(WebGL.UniformLocation location, bool transpose, Float32List array) => gl.uniformMatrix4fv(location, transpose, array);

  void vertexAttrib1f(int indx, num x) => gl.vertexAttrib1f(indx, x);

  void vertexAttrib1fv(int indx, Float32List values) => gl.vertexAttrib1fv(indx, values);

  void vertexAttrib2f(int indx, num x, num y) => gl.vertexAttrib2f(indx, x, y);

  void vertexAttrib2fv(int indx, Float32List values) => gl.vertexAttrib2fv(indx, values);

  void vertexAttrib3f(int indx, num x, num y, num z) => gl.vertexAttrib3f(indx, x, y, z);

  void vertexAttrib3fv(int indx, Float32List values) => gl.vertexAttrib3fv(indx, values);

  void vertexAttrib4f(int indx, num x, num y, num z, num w) => gl.vertexAttrib4f(indx, x, y, z, w);

  void vertexAttrib4fv(int indx, Float32List values) => gl.vertexAttrib4fv(indx, values);

}
