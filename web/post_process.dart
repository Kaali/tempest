part of tempest;

abstract class PostProcessPass {
  WebGL.Framebuffer _fbo;
  WebGL.Texture _fboTex;
  int _width;
  int _height;
  VertexUVBuffer _vertexUVBuffer;
  Shader _shader;
  int _aPosition;
  int _aTexCoord;

  PostProcessPass() {
  }

  WebGL.Texture get outputTex => _fboTex;
  WebGL.Program get program => _shader._program;

  void _bindShader(GraphicsContext gc);
  Shader _setupShader(GraphicsContext gc);

  WebGL.Texture _createTexture(GraphicsContext gc, int width, int height) {
    var gl = gc.gl;
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

  void _createFBO(GraphicsContext gc) {
    var gl = gc.gl;
    _fbo = gl.createFramebuffer();
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _fbo);
    gl.framebufferTexture2D(
        WebGL.FRAMEBUFFER, WebGL.COLOR_ATTACHMENT0, WebGL.TEXTURE_2D, _fboTex, 0);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  void _createVertexBuffer(GraphicsContext gc) {
    var vertices = [
        -1.0, -1.0, 0.0, 0.0, 0.0,
        -1.0, 1.0, 0.0, 0.0, 1.0,
        1.0, 1.0, 0.0, 1.0, 1.0,
        1.0, -1.0, 0.0, 1.0, 0.0,
    ];
    _vertexUVBuffer = new VertexUVBuffer(
        gc.gl, vertices, [0, 1, 2, 3],
        mode:WebGL.RenderingContext.TRIANGLE_FAN);
  }

  void setup(GraphicsContext gc, int width, int height) {
    _width = width;
    _height = height;

    _fboTex = _createTexture(gc, width, height);
    _createFBO(gc);
    _createVertexBuffer(gc);
    _shader = _setupShader(gc);
    _aPosition = _shader.getAttribute('aPosition');
    _aTexCoord = _shader.getAttribute('aTexCoord');
  }

  // Capture draws in fun to FBO texture
  void withBind(GraphicsContext gc, void fun(GraphicsContext gc)) {
    var gl = gc.gl;
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _fbo);
    fun(gc);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  void _draw(GraphicsContext gc) {
    var gl = gc.gl;
    gl.useProgram(_shader._program);
    _bindShader(gc);
    _vertexUVBuffer.bind(gl, _aPosition, _aTexCoord);
    _vertexUVBuffer.draw(gl);
  }
}

class CaptureProcess extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;

  CaptureProcess() {
  }

  @override
  void _bindShader(GraphicsContext gc) {
    var gl = gc.gl;
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, outputTex);
    gl.uniform1i(_uSampler0, 0);
  }

  @override
  Shader _setupShader(GraphicsContext gc) {
    var shader = gc.getShader('capture');
    _uSampler0 = shader.getUniform('uSampler0');
    return shader;
  }

  void process(GraphicsContext gc) {
    withBind(gc, draw);
  }

  void draw(GraphicsContext gc) {
    _draw(gc);
  }
}

class GaussianHorizontalPass extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;
  WebGL.UniformLocation _uSize;
  WebGL.UniformLocation _uBlurAmount;
  WebGL.UniformLocation _uBlurScale;
  WebGL.UniformLocation _uBlurStrength;
  WebGL.Texture _inputTex;

  @override
  void _bindShader(GraphicsContext gc) {
    var gl = gc.gl;
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex);
    gl.uniform1i(_uSampler0, 0);

    gl.uniform1f(_uSize, 2.0 / _width);
    gl.uniform1i(_uBlurAmount, 10);
    gl.uniform1f(_uBlurScale, 2.0);
    gl.uniform1f(_uBlurStrength, 0.9);
  }

  @override
  Shader _setupShader(GraphicsContext gc) {
    var shader = gc.getShader('gaussian_hor');
    _uSampler0 = shader.getUniform('uSampler0');
    _uSize = shader.getUniform('uSize');
    _uBlurAmount = shader.getUniform('uBlurAmount');
    _uBlurScale = shader.getUniform('uBlurScale');
    _uBlurStrength = shader.getUniform('uBlurStrength');
    return shader;
  }

  void process(GraphicsContext gc, WebGL.Texture inputTex) {
    withBind(gc, (gc) => draw(gc, inputTex));
  }

  void draw(GraphicsContext gc, WebGL.Texture inputTex) {
    _inputTex = inputTex;
    _draw(gc);
    _inputTex = null;
  }
}

class BlendPass extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;
  WebGL.UniformLocation _uSampler1;
  WebGL.Texture _inputTex1;
  WebGL.Texture _inputTex2;

  @override
  void _bindShader(GraphicsContext gc) {
    var gl = gc.gl;
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex1);
    gl.uniform1i(_uSampler0, 0);

    gl.activeTexture(WebGL.TEXTURE1);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex2);
    gl.uniform1i(_uSampler1, 1);
  }

  @override
  Shader _setupShader(GraphicsContext gc) {
    var shader = gc.getShader('blend');
    _uSampler0 = shader.getUniform('uSampler0');
    _uSampler1 = shader.getUniform('uSampler1');
    return shader;
  }

  void process(GraphicsContext gc, WebGL.Texture inputTex1, WebGL.Texture inputTex2) {
    withBind(gc, (gc) => draw(gc, inputTex1, inputTex2));
  }

  void draw(GraphicsContext gc, WebGL.Texture inputTex1, WebGL.Texture inputTex2) {
    _inputTex1 = inputTex1;
    _inputTex2 = inputTex2;
    _draw(gc);
    _inputTex1 = null;
    _inputTex2 = null;
  }
}

class ScanlinePass extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;
  WebGL.UniformLocation _uSize;
  WebGL.Texture _inputTex;

  @override
  void _bindShader(GraphicsContext gc) {
    var gl = gc.gl;
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex);
    gl.uniform1i(_uSampler0, 0);

    gl.uniform1f(_uSize, 2000.0);
  }

  @override
  Shader _setupShader(GraphicsContext gc) {
    var shader = gc.getShader('scanline');
    _uSampler0 = shader.getUniform('uSampler0');
    _uSize = shader.getUniform('uSize');
    return shader;
  }

  void process(GraphicsContext gc, WebGL.Texture inputTex) {
    withBind(gc, (gc) => draw(gc, inputTex));
  }

  void draw(GraphicsContext gc, WebGL.Texture inputTex) {
    _inputTex = inputTex;
    _draw(gc);
    _inputTex = null;
  }
}

