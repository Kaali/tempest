// Heavily borrows structure from Solar3D dart-sample
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Copyright (c) 2014, Väinö Järvelä.

library tempest;

import 'dart:html';
import 'dart:web_gl' as WebGL;
import 'dart:async';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';

part 'camera.dart';
part 'shader.dart';
part 'vertex_uv_buffer.dart';

double timestamp() {
  if (window.performance != null) {
    return window.performance.now();
  } else {
    return new DateTime.now().millisecondsSinceEpoch.toDouble();
  }
}

// Test object
class Box {
  Shader shader;
  WebGL.UniformLocation cameraTransformLocation;
  WebGL.UniformLocation modelTransformLocation;
  int positionAttributeIndex;
  int texCoordIndex;
  int faceIdx;
  WebGL.UniformLocation active;
  VertexUVBuffer vertexUVBuffer;
  Vector3 position;
  double time;
  WebGL.Buffer activeDataBuffer;

  Box() {
    time = 0.0;
    position = new Vector3(0.0, 0.0, -1.0);
  }

  void setup(WebGL.RenderingContext glContext) {
    _setupBuffers(glContext);
    _setupProgram(glContext);
  }

  void _setupBuffers(WebGL.RenderingContext glContext) {
    var vertices = [];
    int sides = 16;
    double theta = 2.0 * Math.PI / sides;
    double c = Math.cos(theta);
    double s = Math.sin(theta);
    double radius = 1.0;
    double depth = 2.0;
    double x = radius;
    double y = 0.0;
    for (int i = 0; i <= sides; ++i) {
      double u = i % 2 == 0 ? 0.0 : 1.0;
      vertices
        ..add(x)
        ..add(y)
        ..add(0.0)
        ..add(u)
        ..add(0.0);

      vertices
        ..add(x)
        ..add(y)
        ..add(depth)
        ..add(u)
        ..add(1.0);

      double oldX = x;
      x = c * x - s * y;
      y = s * oldX + c * y;
    }

    var indices = new List.generate((sides + 1) * 2, (index) => index);

    vertexUVBuffer = new VertexUVBuffer(glContext, vertices, indices, mode:WebGL.RenderingContext.TRIANGLE_STRIP);

    // Indices for active vertex drawing
    var activeData = <double>[];
    for (var idx in new List.generate(sides + 1, (idx) => idx.toDouble())) {
      activeData.add(idx);
      activeData.add(idx);
    }

    // TODO: Extract single buffer class
    activeData = new Float32List.fromList(activeData);
    activeDataBuffer = glContext.createBuffer();
    glContext.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, activeDataBuffer);
    glContext.bufferDataTyped(
        WebGL.RenderingContext.ARRAY_BUFFER,
        activeData,
        WebGL.RenderingContext.STATIC_DRAW);
  }

  void _setupProgram(WebGL.RenderingContext glContext) {
    var vertexShader = '''
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    attribute float aFaceIdx;
    uniform float uActive;
    uniform mat4 uCameraTransform;
    uniform mat4 uModelTransform;

    varying vec2 vTexCoord;
    varying float vActive;

    void main(void) {
      vec4 pos = uCameraTransform * uModelTransform * vec4(aPosition, 1.0);
      gl_Position = pos;
      vTexCoord = aTexCoord;
      vActive = abs(aFaceIdx - uActive) < 0.00001 ? 1.0 : 0.0;
    }
    ''';

    // TODO: Active face shader feature for targeting
    var fragmentShader = '''
    precision highp float;

    varying vec2 vTexCoord;
    varying float vActive;

    void main(void) {
      float width = 0.04;
      float edgeX = (vTexCoord.x < width || vTexCoord.x > 1.0 - width) ? 1.0 : 0.0;
      float edgeY = (vTexCoord.y < width || vTexCoord.y > 1.0 - width) ? 1.0 : 0.0;
      float edge = min(1.0, edgeX + edgeY);
      bool isActive = vActive > 0.0;
      if (edge == 1.0) {
        // Edges
        if (isActive) {
          gl_FragColor = vec4(1.0 * edge, 0.0, 1.0 * edge, 1.0);
        } else {
          gl_FragColor = vec4(0.0, 1.0 * edge, 0.0, 1.0);
        }
      } else {
        // Inner
        if (isActive) {
          gl_FragColor = vec4(0.5, 0.2, 0.2, 1.0);
        } else {
          gl_FragColor = vec4(0.1, 0.2, 0.1, 1.0);
        }
      }

      // fog test just for kicks
      float fogNear = 0.1;
      float fogFar = 2.8;
      float depth = gl_FragCoord.z / gl_FragCoord.w;
      float fog = smoothstep(fogNear, fogFar, depth);
      gl_FragColor = mix(gl_FragColor, vec4(0.0, 0.0, 0.0, gl_FragColor.w), fog);
    }
    ''';
    shader = new Shader(vertexShader, fragmentShader);
    shader.compile(glContext);
    shader.link(glContext);

    cameraTransformLocation = glContext.getUniformLocation(shader.program,'uCameraTransform');
    assert(cameraTransformLocation != -1);
    modelTransformLocation = glContext.getUniformLocation(shader.program,'uModelTransform');
    assert(modelTransformLocation != -1);
    positionAttributeIndex = glContext.getAttribLocation(shader.program, 'aPosition');
    assert(positionAttributeIndex != -1);
    texCoordIndex = glContext.getAttribLocation(shader.program, 'aTexCoord');
    assert(texCoordIndex != -1);
    faceIdx = glContext.getAttribLocation(shader.program, 'aFaceIdx');
    assert(faceIdx != -1);
    active = glContext.getUniformLocation(shader.program, 'uActive');
    assert(active != -1);
  }

  void update(double timeStep) {
    time += timeStep;
    position = new Vector3(Math.sin(time), 0.0, -3.0);
  }

  void render(WebGL.RenderingContext glContext, Float32List cameraTransform) {
    glContext.useProgram(shader.program);
    glContext.uniformMatrix4fv(cameraTransformLocation, false, cameraTransform);

    var modelTransform = new Matrix4.translation(position);
    var modelTransformMatrix = new Float32List(16);
    modelTransform.copyIntoArray(modelTransformMatrix, 0);
    glContext.uniformMatrix4fv(modelTransformLocation, false, modelTransformMatrix);

    glContext.bindBuffer(WebGL.RenderingContext.ARRAY_BUFFER, activeDataBuffer);
    glContext.enableVertexAttribArray(faceIdx);
    glContext.vertexAttribPointer(
        faceIdx,
        1, WebGL.RenderingContext.FLOAT,
        false, 4,
        0
    );

    // TODO: Does not match and has fun bugs when it does
    glContext.uniform1f(active, 1.0);

    // Bind vertices
    vertexUVBuffer.bind(glContext, positionAttributeIndex, texCoordIndex);
    vertexUVBuffer.draw(glContext);
  }
}

class Tempest {
  Camera camera;
  Box box;

  Tempest(num aspectRatio) {
    camera = new Camera(45.0, aspectRatio, 1.0, 1000.0);
    box = new Box();
  }

  void setup(WebGL.RenderingContext glContext) {
    // TODO: Async setup and manager for shaders etc.
    box.setup(glContext);
  }

  void update(double timeStep) {
    box.update(timeStep);
  }

  void render(double timeStep, WebGL.RenderingContext glContext) {
    box.render(glContext, camera.cameraTransform);
  }

  void onKeyDown(KeyboardEvent event) {
  }

  void onKeyUp(KeyboardEvent event) {
  }
}

class TempestApplication {
  WebGL.RenderingContext glContext;
  CanvasElement canvas;
  Tempest tempest;

  int get width => canvas.width;
  int get height => canvas.height;
  num get aspectRatio => width / height;

  // Timing
  double now;
  double deltaTime = 0.0;
  double lastTime = timestamp();
  double timeStep = 1 / 60.0;

  void startup(String canvasId) {
    canvas = querySelector(canvasId);
    glContext = canvas.getContext('experimental-webgl');
    if (glContext == null) {
      canvas.parent.text = "Browser does not support WebGL";
      return;
    }

    canvas.width = canvas.parent.client.width;
    canvas.height = 400;

    Future f = setupAssets();
    f.then((_) {
      bind();
      requestRAF();
    });
  }

  Future setupAssets() {
    tempest = new Tempest(aspectRatio);
    tempest.setup(glContext);
    return new Future(() => null);
  }

  void bind() {
    document.onKeyDown.listen(onKeyDown);
    document.onKeyUp.listen(onKeyUp);
  }

  void onKeyDown(KeyboardEvent event) {
    tempest.onKeyDown(event);
  }

  void onKeyUp(KeyboardEvent event) {
    tempest.onKeyUp(event);
  }

  void rAF(double time) {
    now = timestamp();
    deltaTime += Math.min(1.0, (now - lastTime) / 1000.0);
    while (deltaTime > timeStep) {
      deltaTime -= timeStep;
      update(timeStep);
    }
    render(deltaTime);
    lastTime = now;
    requestRAF();
  }

  void update(double timeStep) {
    tempest.update(timeStep);
  }

  void render(double timeStep) {
    glContext.viewport(0, 0, width, height);
    glContext.clearColor(0.0, 0.0, 0.0, 1.0);
    glContext.clearDepth(1.0);
    glContext.clear(
        WebGL.RenderingContext.COLOR_BUFFER_BIT |
        WebGL.RenderingContext.DEPTH_BUFFER_BIT);

    tempest.render(timeStep, glContext);
  }

  void requestRAF() {
    window.requestAnimationFrame(rAF);
  }
}

TempestApplication application = new TempestApplication();

void main() {
  application.startup('#container');
}
