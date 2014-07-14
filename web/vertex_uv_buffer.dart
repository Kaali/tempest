part of tempest;

class VertexUVBuffer {
  WebGL.Buffer _vertexBuffer;
  WebGL.Buffer _indexBuffer;
  int _vertexCount;
  int _vertexStride;
  int _uvOffset;
  int _mode;

  VertexUVBuffer(GraphicsContext gc, List<double> vertices,
                 {List<int> indices : null,
                 int mode : WebGL.RenderingContext.TRIANGLES}) {
    assert(vertices.length % 5 == 0);
    assert(indices == null || indices.every((x) => x >= 0 && x < vertices.length / 5));

    _mode = mode;

    var gl = gc.gl;
    var vertexData = new Float32List.fromList(vertices);
    _vertexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, _vertexBuffer);
    gl.bufferDataTyped(
        WebGL.RenderingContext.ARRAY_BUFFER,
        vertexData,
        WebGL.RenderingContext.STATIC_DRAW);

    if (indices != null) {
      _indexBuffer = gl.createBuffer();
      gl.bindBuffer(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, _indexBuffer);
      gl.bufferDataTyped(
          WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER,
          new Uint16List.fromList(indices),
          WebGL.RenderingContext.STATIC_DRAW);
      _vertexCount = indices.length;
    } else {
      _vertexCount = (vertices.length / 5).toInt();
    }

    _vertexStride = vertexData.elementSizeInBytes * 5;
    _uvOffset = vertexData.elementSizeInBytes * 3;
  }

  factory VertexUVBuffer.square(GraphicsContext gc, {double size : 1.0}) {
    var vertices = <double>[
        -size, -size, 0.0, 0.0, 0.0,
        size, -size, 0.0, 1.0, 0.0,
        size, size, 0.0, 1.0, 1.0,
        -size, size, 0.0, 0.0, 1.0,
    ];
    return new VertexUVBuffer(gc, vertices,
        mode:WebGL.RenderingContext.TRIANGLE_FAN);
  }

  void bind(GraphicsContext gc, int positionAttribute, int uvAttribute) {
    var gl = gc.gl;
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, _vertexBuffer);
    gl.enableVertexAttribArray(positionAttribute);
    gl.vertexAttribPointer(
        positionAttribute,
        3, WebGL.RenderingContext.FLOAT,
        false, _vertexStride,
        0);

    gl.enableVertexAttribArray(uvAttribute);
    gl.vertexAttribPointer(
        uvAttribute,
        2, WebGL.RenderingContext.FLOAT,
        false, _vertexStride,
        _uvOffset
    );
  }

  void draw(GraphicsContext gc) {
    var gl = gc.gl;
    if (_indexBuffer == null) {
      gl.drawArrays(_mode, 0, _vertexCount);
    } else {
      gl.bindBuffer(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, _indexBuffer);
      gl.drawElements(
          _mode, _vertexCount,
          WebGL.RenderingContext.UNSIGNED_SHORT, 0);
    }
  }
}
