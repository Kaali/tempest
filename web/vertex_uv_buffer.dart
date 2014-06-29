part of tempest;

class VertexUVBuffer {
  WebGL.Buffer _vertexBuffer;
  WebGL.Buffer _indexBuffer;
  int _vertexCount;
  int _vertexStride;
  int _uvOffset;
  int _mode;

  VertexUVBuffer(WebGL.RenderingContext gl, List<double> vertices,
                 List<int> indices,
                 {int mode : WebGL.RenderingContext.TRIANGLE_FAN}) {
    assert(vertices.length % 5 == 0);
    assert(indices.every((x) => x >= 0 && x < vertices.length / 5));

    _mode = mode;

    var vertexData = new Float32List.fromList(vertices);
    _vertexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, _vertexBuffer);
    gl.bufferDataTyped(
        WebGL.RenderingContext.ARRAY_BUFFER,
        vertexData,
        WebGL.RenderingContext.STATIC_DRAW);

    _indexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    gl.bufferDataTyped(
        WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER,
        new Uint16List.fromList(indices),
        WebGL.RenderingContext.STATIC_DRAW);

    _vertexCount = indices.length;
    _vertexStride = vertexData.elementSizeInBytes * 5;
    _uvOffset = vertexData.elementSizeInBytes * 3;
  }

  void bind(WebGL.RenderingContext gl, int positionAttribute, int uvAttribute) {
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

  void draw(WebGL.RenderingContext gl) {
    gl.bindBuffer(WebGL.RenderingContext.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    gl.drawElements(
        _mode, _vertexCount,
        WebGL.RenderingContext.UNSIGNED_SHORT, 0);
  }
}
