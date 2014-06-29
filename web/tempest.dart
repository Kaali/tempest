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
  VertexUVBuffer vertexUVBuffer;
  Vector3 position;
  double time;

  Box() {
    time = 0.0;
    position = new Vector3(0.0, 0.0, -1.0);
  }

  void setup(WebGL.RenderingContext glContext) {
    _setupBuffers(glContext);
    _setupProgram(glContext);
  }

  void _setupBuffers(WebGL.RenderingContext glContext) {
    var vertices = const [
    0.000000, 1.000000, -2.000000, 0.882851, 0.000353,
    0.000000, 1.000000, 2.000000, 0.882852, 0.499647,
    0.382683, 0.923880, 2.000000, 0.785444, 0.499647,
    0.382683, 0.923880, -2.000000, 0.785444, 0.000353,
    0.382683, 0.923880, -2.000000, 0.490398, 0.500353,
    0.382683, 0.923880, 2.000000, 0.490398, 0.999647,
    0.707107, 0.707107, 2.000000, 0.392991, 0.999647,
    0.707107, 0.707107, -2.000000, 0.392991, 0.500353,
    0.707107, 0.707107, -2.000000, 0.196046, 0.500353,
    0.707107, 0.707107, 2.000000, 0.196046, 0.999647,
    0.923880, 0.382683, 2.000000, 0.098638, 0.999647,
    0.923880, 0.382683, -2.000000, 0.098638, 0.500353,
    0.923880, 0.382683, -2.000000, 0.294163, 0.000353,
    0.923880, 0.382683, 2.000000, 0.294168, 0.499647,
    1.000000, -0.000000, 2.000000, 0.196760, 0.499648,
    1.000000, -0.000000, -2.000000, 0.196756, 0.000354,
    1.000000, -0.000000, -2.000000, 0.196046, 0.000353,
    1.000000, -0.000000, 2.000000, 0.196050, 0.499647,
    0.923880, -0.382684, 2.000000, 0.098643, 0.499648,
    0.923880, -0.382684, -2.000000, 0.098638, 0.000354,
    0.923880, -0.382684, -2.000000, 0.490399, 0.000353,
    0.923880, -0.382684, 2.000000, 0.490398, 0.499647,
    0.707107, -0.707107, 2.000000, 0.392991, 0.499647,
    0.707107, -0.707107, -2.000000, 0.392991, 0.000353,
    0.707107, -0.707107, -2.000000, 0.588512, 0.000353,
    0.707107, -0.707107, 2.000000, 0.588512, 0.499647,
    0.382683, -0.923880, 2.000000, 0.491104, 0.499647,
    0.382683, -0.923880, -2.000000, 0.491105, 0.000353,
    0.382683, -0.923880, -2.000000, 0.392281, 0.000353,
    0.382683, -0.923880, 2.000000, 0.392285, 0.499647,
    0.000000, -1.000000, 2.000000, 0.294878, 0.499647,
    0.000000, -1.000000, -2.000000, 0.294873, 0.000354,
    0.000000, -1.000000, -2.000000, 0.294159, 0.500353,
    0.000000, -1.000000, 2.000000, 0.294159, 0.999647,
    -0.382683, -0.923880, 2.000000, 0.196751, 0.999647,
    -0.382683, -0.923880, -2.000000, 0.196751, 0.500353,
    -0.382683, -0.923880, -2.000000, 0.097933, 0.000387,
    -0.382683, -0.923880, 2.000000, 0.097760, 0.499680,
    -0.707107, -0.707107, 2.000000, 0.000353, 0.499647,
    -0.707107, -0.707107, -2.000000, 0.000525, 0.000353,
    -0.707107, -0.707107, -2.000000, 0.588512, 0.500352,
    -0.707107, -0.707107, 2.000000, 0.588512, 0.999646,
    -0.923880, -0.382684, 2.000000, 0.491104, 0.999646,
    -0.923880, -0.382684, -2.000000, 0.491104, 0.500352,
    -0.923880, -0.382684, -2.000000, 0.686625, 0.000353,
    -0.923880, -0.382684, 2.000000, 0.686625, 0.499647,
    -1.000000, 0.000000, 2.000000, 0.589218, 0.499647,
    -1.000000, 0.000000, -2.000000, 0.589218, 0.000353,
    -1.000000, 0.000000, -2.000000, 0.980965, 0.000353,
    -1.000000, 0.000000, 2.000000, 0.980965, 0.499647,
    -0.923879, 0.382684, 2.000000, 0.883557, 0.499647,
    -0.923879, 0.382684, -2.000000, 0.883557, 0.000353,
    -0.923879, 0.382684, -2.000000, 0.686625, 0.500352,
    -0.923879, 0.382684, 2.000000, 0.686625, 0.999646,
    -0.707107, 0.707107, 2.000000, 0.589218, 0.999646,
    -0.707107, 0.707107, -2.000000, 0.589218, 0.500352,
    -0.707107, 0.707107, -2.000000, 0.784738, 0.000353,
    -0.707107, 0.707107, 2.000000, 0.784738, 0.499647,
    -0.382683, 0.923880, 2.000000, 0.687331, 0.499647,
    -0.382683, 0.923880, -2.000000, 0.687331, 0.000353,
    0.000000, 1.000000, 2.000000, 0.687331, 0.999646,
    0.000000, 1.000000, -2.000000, 0.687331, 0.500352,
    -0.382683, 0.923880, -2.000000, 0.784738, 0.500352,
    -0.382683, 0.923880, 2.000000, 0.784738, 0.999646
    ];

    var indices = const [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10,
    11, 12, 13, 14, 12, 14, 15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23,
    24, 25, 26, 24, 26, 27, 28, 29, 30, 28, 30, 31, 32, 33, 34, 32, 34, 35, 36,
    37, 38, 36, 38, 39, 40, 41, 42, 40, 42, 43, 44, 45, 46, 44, 46, 47, 48, 49,
    50, 48, 50, 51, 52, 53, 54, 52, 54, 55, 56, 57, 58, 56, 58, 59, 60, 61, 62,
    60, 62, 63];

    vertexUVBuffer = new VertexUVBuffer(glContext, vertices, indices);
  }

  void _setupProgram(WebGL.RenderingContext glContext) {
    var vertexShader = '''
    attribute vec3 aPosition;
    attribute vec2 aTexCoord;
    uniform mat4 uCameraTransform;
    uniform mat4 uModelTransform;

    varying vec2 vTexCoord;

    void main(void) {
      vec4 pos = uCameraTransform * uModelTransform * vec4(aPosition, 1.0);
      gl_Position = pos;
      vTexCoord = aTexCoord;
    }
    ''';
    var fragmentShader = '''
    precision highp float;

    varying vec2 vTexCoord;

    void main(void) {
      float width = 0.01;
      float edgeX = (vTexCoord.x < width || vTexCoord.x > 1.0 - width) ? 1.0 : 0.0;
      float edgeY = (vTexCoord.y < width || vTexCoord.y > 1.0 - width) ? 1.0 : 0.0;
      float edge = min(1.0, edgeX + edgeY);
      if (edge == 1.0) {
        // Edges
        gl_FragColor = vec4(1.0 * edge, 0.0, 0.0, 1.0);
      } else {
        // Inner
        gl_FragColor = vec4(vTexCoord.x, vTexCoord.y, 0.0, 1.0);
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
  }

  void update(double timeStep) {
    time += timeStep;
    position = new Vector3(Math.sin(time), 0.0, -1.0);
  }

  void render(WebGL.RenderingContext glContext, Float32List cameraTransform) {
    glContext.useProgram(shader.program);
    glContext.uniformMatrix4fv(cameraTransformLocation, false, cameraTransform);

    var modelTransform = new Matrix4.translation(position);
    var modelTransformMatrix = new Float32List(16);
    modelTransform.copyIntoArray(modelTransformMatrix, 0);
    glContext.uniformMatrix4fv(modelTransformLocation, false, modelTransformMatrix);

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
