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

  void setup(GraphicsContext gc, int width, int height) {
    _width = width;
    _height = height;

    _fboTex = gc.createRGBATexture(width, height);
    _fbo = gc.createFBO(_fboTex, WebGL.COLOR_ATTACHMENT0);
    _vertexUVBuffer = new VertexUVBuffer.square(gc);
    _shader = _setupShader(gc);
    _aPosition = _shader.getAttribute('aPosition');
    _aTexCoord = _shader.getAttribute('aTexCoord');
  }

  // Capture draws in fun to FBO texture
  void withBind(GraphicsContext gc, void boundFb(GraphicsContext)) {
    gc.withBindFramebuffer(_fbo, boundFb);
  }

  void _draw(GraphicsContext gc) {
    var gl = gc.gl;
    gc.useShader(_shader);
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
    gc.bindTexture(outputTex, 0);
    gc.uniform1i(_uSampler0, 0);
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
    gc.bindTexture(_inputTex, 0);
    gc.uniform1i(_uSampler0, 0);

    gc.uniform1f(_uSize, 2.0 / _width);
    gc.uniform1i(_uBlurAmount, 10);
    gc.uniform1f(_uBlurScale, 2.0);
    gc.uniform1f(_uBlurStrength, 0.9);
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
    gc.bindTexture(_inputTex1, 0);
    gc.uniform1i(_uSampler0, 0);

    gc.bindTexture(_inputTex2, 1);
    gc.uniform1i(_uSampler1, 1);
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
    gc.bindTexture(_inputTex, 0);
    gc.uniform1i(_uSampler0, 0);
    gc.uniform1f(_uSize, 2000.0);
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

