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

  String get _fragmentShader;
  WebGL.Texture get outputTex => _fboTex;
  WebGL.Program get program => _shader.program;
  void _bindShader(WebGL.RenderingContext gl);
  void _setupShader(WebGL.RenderingContext gl);
  // Implement your own process -function with necessary arguments

  WebGL.Texture _createTexture(WebGL.RenderingContext gl, int width, int height) {
    WebGL.Texture tex = gl.createTexture();
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

    _shader = new Shader(vertexShader, _fragmentShader);
    _shader.compile(gl);
    _shader.link(gl);

    _aPosition = gl.getAttribLocation(_shader.program, 'aPosition');
    assert(_aPosition != 0);
    _aTexCoord = gl.getAttribLocation(_shader.program, 'aTexCoord');
    assert(_aTexCoord != 0);
  }

  void setup(WebGL.RenderingContext gl, int width, int height) {
    _width = width;
    _height = height;

    _fboTex = _createTexture(gl, width, height);
    _createFBO(gl);
    _createVertexBuffer(gl);
    _createShader(gl);
    _setupShader(gl);
  }

  // Capture draws in fun to FBO texture
  void withBind(WebGL.RenderingContext gl, void fun(WebGL.RenderingContext gl)) {
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, _fbo);
    fun(gl);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  void _draw(WebGL.RenderingContext gl) {
    gl.useProgram(_shader.program);
    _bindShader(gl);
    _vertexUVBuffer.bind(gl, _aPosition, _aTexCoord);
    _vertexUVBuffer.draw(gl);
  }
}

class CaptureProcess extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;

  CaptureProcess() {
  }

  String get _fragmentShader => '''
    precision highp float;

    uniform sampler2D uSampler0;
    varying vec2 vTexCoord;

    void main() {
      gl_FragColor = texture2D(uSampler0, vTexCoord);
    }
    ''';


  void _bindShader(WebGL.RenderingContext gl) {
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, outputTex);
    gl.uniform1i(_uSampler0, 0);
  }

  void _setupShader(WebGL.RenderingContext gl) {
    _uSampler0 = gl.getUniformLocation(program, 'uSampler0');
    assert(_uSampler0 != 0);
  }

  void process(WebGL.RenderingContext gl) {
    withBind(gl, draw);
  }

  void draw(WebGL.RenderingContext gl) {
    _draw(gl);
  }
}

class GaussianHorizontalPass extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;
  WebGL.UniformLocation _uSize;
  WebGL.UniformLocation _uBlurAmount;
  WebGL.UniformLocation _uBlurScale;
  WebGL.UniformLocation _uBlurStrength;
  WebGL.Texture _inputTex;

  // Adapted from:
  // https://web.archive.org/web/20121003045153/http://devmaster.net/posts/3100/shader-effects-glow-and-bloom
  String get _fragmentShader => '''
    precision highp float;

    uniform float uSize;
    uniform int uBlurAmount;
    uniform float uBlurScale;
    uniform float uBlurStrength;

    uniform sampler2D uSampler0;
    varying vec2 vTexCoord;

    float Gaussian (float x, float deviation) {
      return (1.0 / sqrt(2.0 * 3.141592 * deviation)) * exp(-((x * x) / (2.0 * deviation)));
    }

    void main() {
      float halfBlur = float(uBlurAmount) * 0.5;
      vec4 color = vec4(0.0);
      vec4 texColor = vec4(0.0);

      float deviation = halfBlur * 0.35;
      deviation *= deviation;
      float strength = 1.0 - uBlurStrength;

      for (int i = 0; i < 10; ++i) {
        if (i >= uBlurAmount) break;
        float offset = float(i) - halfBlur;
        texColor = texture2D(uSampler0, vTexCoord + vec2(offset * uSize * uBlurScale, 0.0)) *
          Gaussian(offset * strength, deviation);
        color += texColor;
      }

      gl_FragColor = clamp(color, 0.0, 1.0);
      gl_FragColor.w = 1.0;
    }
    ''';

  void _bindShader(WebGL.RenderingContext gl) {
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex);
    gl.uniform1i(_uSampler0, 0);

    gl.uniform1f(_uSize, 1.0 / _width);
    gl.uniform1i(_uBlurAmount, 10);
    gl.uniform1f(_uBlurScale, 3.0);
    gl.uniform1f(_uBlurStrength, 0.8);
  }

  void _setupShader(WebGL.RenderingContext gl) {
    _uSampler0 = gl.getUniformLocation(program, 'uSampler0');
    assert(_uSampler0 != 0);
    _uSize = gl.getUniformLocation(program, 'uSize');
    assert(_uSize != 0);
    _uBlurAmount = gl.getUniformLocation(program, 'uBlurAmount');
    assert(_uBlurAmount != 0);
    _uBlurScale = gl.getUniformLocation(program, 'uBlurScale');
    assert(_uBlurScale != 0);
    _uBlurStrength = gl.getUniformLocation(program, 'uBlurStrength');
    assert(_uBlurStrength != 0);
  }

  void process(WebGL.RenderingContext gl, WebGL.Texture inputTex) {
    withBind(gl, (gl) => draw(gl, inputTex));
  }

  void draw(WebGL.RenderingContext gl, WebGL.Texture inputTex) {
    _inputTex = inputTex;
    _draw(gl);
    _inputTex = null;
  }
}

class BlendPass extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;
  WebGL.UniformLocation _uSampler1;
  WebGL.Texture _inputTex1;
  WebGL.Texture _inputTex2;

  // Adapted from:
  // https://web.archive.org/web/20121003045153/http://devmaster.net/posts/3100/shader-effects-glow-and-bloom
  String get _fragmentShader => '''
    precision highp float;

    uniform sampler2D uSampler0;
    uniform sampler2D uSampler1;
    varying vec2 vTexCoord;

    void main() {
      vec4 dst = texture2D(uSampler0, vTexCoord);
      vec4 src = texture2D(uSampler1, vTexCoord);

      //gl_FragColor = clamp((src + dst) - (src * dst), 0.0, 1.0);
      //gl_FragColor.w = 1.0;
      src = (src * 0.5) + 0.5;
      gl_FragColor.xyz = vec3((src.x <= 0.5) ? (dst.x - (1.0 - 2.0 * src.x) * dst.x * (1.0 - dst.x)) : (((src.x > 0.5) && (dst.x <= 0.25)) ? (dst.x + (2.0 * src.x - 1.0) * (4.0 * dst.x * (4.0 * dst.x + 1.0) * (dst.x - 1.0) + 7.0 * dst.x)) : (dst.x + (2.0 * src.x - 1.0) * (sqrt(dst.x) - dst.x))),
        (src.y <= 0.5) ? (dst.y - (1.0 - 2.0 * src.y) * dst.y * (1.0 - dst.y)) : (((src.y > 0.5) && (dst.y <= 0.25)) ? (dst.y + (2.0 * src.y - 1.0) * (4.0 * dst.y * (4.0 * dst.y + 1.0) * (dst.y - 1.0) + 7.0 * dst.y)) : (dst.y + (2.0 * src.y - 1.0) * (sqrt(dst.y) - dst.y))),
        (src.z <= 0.5) ? (dst.z - (1.0 - 2.0 * src.z) * dst.z * (1.0 - dst.z)) : (((src.z > 0.5) && (dst.z <= 0.25)) ? (dst.z + (2.0 * src.z - 1.0) * (4.0 * dst.z * (4.0 * dst.z + 1.0) * (dst.z - 1.0) + 7.0 * dst.z)) : (dst.z + (2.0 * src.z - 1.0) * (sqrt(dst.z) - dst.z))));
      gl_FragColor.w = 1.0;
    }
    ''';

  void _bindShader(WebGL.RenderingContext gl) {
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex1);
    gl.uniform1i(_uSampler0, 0);

    gl.activeTexture(WebGL.TEXTURE1);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex2);
    gl.uniform1i(_uSampler1, 1);
  }

  void _setupShader(WebGL.RenderingContext gl) {
    _uSampler0 = gl.getUniformLocation(program, 'uSampler0');
    assert(_uSampler0 != 0);
    _uSampler1 = gl.getUniformLocation(program, 'uSampler1');
    assert(_uSampler1 != 0);
  }

  void process(WebGL.RenderingContext gl, WebGL.Texture inputTex1, WebGL.Texture inputTex2) {
    withBind(gl, (gl) => draw(gl, inputTex1, inputTex2));
  }

  void draw(WebGL.RenderingContext gl, WebGL.Texture inputTex1, WebGL.Texture inputTex2) {
    _inputTex1 = inputTex1;
    _inputTex2 = inputTex2;
    _draw(gl);
    _inputTex1 = null;
    _inputTex2 = null;
  }
}

class ScanlinePass extends PostProcessPass {
  WebGL.UniformLocation _uSampler0;
  WebGL.UniformLocation _uSize;
  WebGL.Texture _inputTex;

  String get _fragmentShader => '''
    precision highp float;

    uniform float uSize;

    uniform sampler2D uSampler0;
    varying vec2 vTexCoord;

    void main() {
      gl_FragColor = texture2D(uSampler0, vTexCoord) * clamp(sin(vTexCoord.y * uSize), 0.6, 1.0);
      gl_FragColor.w = 1.0;
    }
    ''';

  void _bindShader(WebGL.RenderingContext gl) {
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, _inputTex);
    gl.uniform1i(_uSampler0, 0);

    gl.uniform1f(_uSize, 800.0);
  }

  void _setupShader(WebGL.RenderingContext gl) {
    _uSampler0 = gl.getUniformLocation(program, 'uSampler0');
    assert(_uSampler0 != 0);
    _uSize = gl.getUniformLocation(program, 'uSize');
    assert(_uSize != 0);
  }

  void process(WebGL.RenderingContext gl, WebGL.Texture inputTex) {
    withBind(gl, (gl) => draw(gl, inputTex));
  }

  void draw(WebGL.RenderingContext gl, WebGL.Texture inputTex) {
    _inputTex = inputTex;
    _draw(gl);
    _inputTex = null;
  }
}

