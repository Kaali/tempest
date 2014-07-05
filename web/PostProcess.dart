part of tempest;

class PostProcess {
  WebGL.Framebuffer _fbo;
  WebGL.Texture _fboTex;
  int _width;
  int _height;
  VertexUVBuffer _vertexUVBuffer;
  Shader _shader;
  WebGL.UniformLocation _uTexture;
  int _aPosition;
  int _aTexCoord;

  PostProcess() {
  }

  void _createTexture(WebGL.RenderingContext gl, int width, int height) {
    _fboTex = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, _fboTex);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, WebGL.CLAMP_TO_EDGE);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, WebGL.CLAMP_TO_EDGE);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
    gl.texImage2D(
        WebGL.TEXTURE_2D, 0, WebGL.RGBA, width, height, 0, WebGL.RGBA,
        WebGL.UNSIGNED_BYTE, null);
  }

  void _createFBO(WebGL.RenderingContext gl) {
    _fbo = gl.createFramebuffer();
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _fbo);
    gl.framebufferTexture2D(
        WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, _fboTex, 0);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  void _createVertexBuffer(WebGL.RenderingContext gl) {
    var vertices = [
        -1.0, -1.0, 0.0, 0.0, 0.0,
        -1.0, 1.0, 0.0, 0.0, 1.0,
        1.0, 1.0, 0.0, 1.0, 1.0,
        1.0, -1.0, 0.0, 1.0, 0.0,
    ];
    _vertexUVBuffer = new VertexUVBuffer(
        gl, vertices, [0, 1, 2, 3],
        mode:WebGL.RenderingContext.TRIANGLE_FAN);
  }

  void _createShader(WebGL.RenderingContext gl) {
    var vertexShader = '''
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    varying vec2 vTexCoord;

    void main() {
      vTexCoord = aTexCoord;
      gl_Position = vec4(aPosition, 1.0);
    }
    ''';

    var fragmentShader = '''
    precision highp float;

    uniform sampler2D uTexture;
    varying vec2 vTexCoord;

    void main() {
      gl_FragColor = texture2D(uTexture, vTexCoord);
    }
    ''';

    _shader = new Shader(vertexShader, fragmentShader);
    _shader.compile(gl);
    _shader.link(gl);

    _aPosition = gl.getAttribLocation(_shader.program, 'aPosition');
    assert(_aPosition != 0);
    _aTexCoord = gl.getAttribLocation(_shader.program, 'aTexCoord');
    assert(_aTexCoord != 0);
    _uTexture = gl.getUniformLocation(_shader.program, 'uTexture');
    assert(_uTexture != 0);
  }

  void setup(WebGL.RenderingContext gl, int width, int height) {
    _width = width;
    _height = height;

    _createTexture(gl, width, height);
    _createFBO(gl);
    _createVertexBuffer(gl);
    _createShader(gl);
  }

  void withBind(WebGL.RenderingContext gl, void fun(WebGL.RenderingContext gl)) {
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _fbo);
    fun(gl);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  void draw(WebGL.RenderingContext gl) {
    gl.useProgram(_shader.program);
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _fboTex);
    gl.uniform1i(_uTexture, 0);
    _vertexUVBuffer.bind(gl, _aPosition, _aTexCoord);
    _vertexUVBuffer.draw(gl);
  }
}
