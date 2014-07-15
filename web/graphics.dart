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

  // State store
  List<WebGL.Texture> _boundTextures;
  List<WebGL.Framebuffer> _framebufferStack;
  List<WebGL.Renderbuffer> _renderbufferStack;
  List<int> _viewport;
  Map<int, bool> _capabilities;
  List<double> _clearColor;
  double _clearDepth;

  WebGL.RenderingContext get gl => _gl;

  GraphicsContext(WebGL.RenderingContext this._gl, int this._width,
                  int this._height)
      : _shaders = new Map<String, Shader>(),
        _boundTextures = new List.filled(WebGL.TEXTURE31 - WebGL.TEXTURE0, null),
        _framebufferStack = <WebGL.Framebuffer>[],
        _renderbufferStack = <WebGL.Renderbuffer>[],
        _viewport = new List<int>(4),
        _capabilities = <int, bool>{},
        _clearColor = new List<double>(4);

  //
  // General
  //
  void clear() {
    viewport(0, 0, _width, _height);
    enable(WebGL.DEPTH_TEST);
    clearColor(0.0, 0.0, 0.0, 1.0);
    clearDepth(1.0);
    gl.clear(
        WebGL.RenderingContext.COLOR_BUFFER_BIT |
        WebGL.RenderingContext.DEPTH_BUFFER_BIT);
  }

  void viewport(int x, int y, int width, int height) {
    if (_viewport[0] != x || _viewport[1] != y || _viewport[2] != width ||
        _viewport[3] != height) {
      gl.viewport(x, y, width, height);
      _viewport[0] = x;
      _viewport[1] = y;
      _viewport[2] = width;
      _viewport[3] = height;
    }
  }

  void clearColor(double r, double g, double b, double a) {
    if (_clearColor[0] != r || _clearColor[1] != g || _clearColor[2] != b ||
    _clearColor[3] != a) {
      gl.clearColor(r, g, b, a);
      _clearColor[0] = r;
      _clearColor[1] = g;
      _clearColor[2] = b;
      _clearColor[3] = a;
    }
  }

  void clearDepth(double depth) {
    if (_clearDepth == null || _clearDepth != depth) {
      gl.clearDepth(depth);
      _clearDepth = depth;
    }
  }

  void enable(int capability) {
    var cur = _capabilities[capability];
    if (cur == null || !cur) {
      gl.enable(capability);
      _capabilities[capability] = true;
    }
  }

  void disable(int capability) {
    var cur = _capabilities[capability];
    if (cur == null || cur) {
      gl.disable(capability);
      _capabilities[capability] = false;
    }
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
    bindFramebuffer(framebuffer);
    try {
      boundFn(this);
    } finally {
      unbindFramebuffer();
    }
  }

  void bindTexture(WebGL.Texture texture, int number) {
    if (_boundTextures[number] != texture) {
      gl.activeTexture(WebGL.TEXTURE0 + number);
      gl.bindTexture(WebGL.TEXTURE_2D, texture);
      _boundTextures[number] = texture;
    }
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
    bindFramebuffer(fb);
    bindRenderbuffer(rb);
    gl.framebufferRenderbuffer(WebGL.FRAMEBUFFER, attachment,
        WebGL.RENDERBUFFER, rb);
    unbindRenderbuffer();
    unbindFramebuffer();
  }

  void withBindRenderbuffer(WebGL.Renderbuffer rb,
                            void boundFn(GraphicsContext)) {
    bindRenderbuffer(rb);
    try {
      boundFn(this);
    } finally {
      unbindRenderbuffer();
    }
  }

  void bindFramebuffer(WebGL.Framebuffer fb) {
    if (_framebufferStack.isEmpty || _framebufferStack.last != fb) {
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, fb);
    }
    _framebufferStack.add(fb);
  }

  void unbindFramebuffer() {
    assert(_framebufferStack.isNotEmpty);
    var current = _framebufferStack.removeLast();
    var next = _framebufferStack.isEmpty ? null : _framebufferStack.last;
    if (next != current) {
      gl.bindFramebuffer(WebGL.FRAMEBUFFER, next);
    }
  }

  void bindRenderbuffer(WebGL.Renderbuffer rb) {
    if (_renderbufferStack.isEmpty || _renderbufferStack.last != rb) {
      gl.bindRenderbuffer(WebGL.RENDERBUFFER, rb);
    }
    _renderbufferStack.add(rb);
  }

  void unbindRenderbuffer() {
    assert(_renderbufferStack.isNotEmpty);
    var current = _renderbufferStack.removeLast();
    var next = _renderbufferStack.isEmpty ? null : _renderbufferStack.last;
    if (next != current) {
      gl.bindRenderbuffer(WebGL.RENDERBUFFER, next);
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
