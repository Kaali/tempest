part of tempest;

class Shader {
  final String vertexShaderSource;
  final String fragmentShaderSource;
  WebGL.Shader vertexShader;
  WebGL.Shader fragmentShader;
  WebGL.Program program;

  Shader(this.vertexShaderSource, this.fragmentShaderSource);

  void compile(WebGL.RenderingContext glContext) {
    vertexShader = glContext.createShader(WebGL.RenderingContext.VERTEX_SHADER);
    glContext.shaderSource(vertexShader, vertexShaderSource);
    glContext.compileShader(vertexShader);
    print(glContext.getShaderInfoLog(vertexShader));

    fragmentShader = glContext.createShader(WebGL.RenderingContext.FRAGMENT_SHADER);
    glContext.shaderSource(fragmentShader, fragmentShaderSource);
    glContext.compileShader(fragmentShader);
    print(glContext.getShaderInfoLog(fragmentShader));
  }

  void link(WebGL.RenderingContext glContext) {
    assert(program == null);
    assert(vertexShader != null);
    assert(fragmentShader != null);

    program = glContext.createProgram();
    glContext.attachShader(program, vertexShader);
    glContext.attachShader(program, fragmentShader);
    glContext.linkProgram(program);
    //print(glContext.getProgramInfoLog(program));
  }
}
