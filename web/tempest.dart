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
part 'level.dart';
part 'postprocess.dart';

double timestamp() {
  if (window.performance != null) {
    return window.performance.now();
  } else {
    return new DateTime.now().millisecondsSinceEpoch.toDouble();
  }
}

abstract class GameObject {
  void setup(WebGL.RenderingContext gl);
  void update(double timeStep);
  void render(WebGL.RenderingContext gl, Float32List cameraTransform);
}

class Tempest {
  Camera camera;
  Level level;
  PostProcess postProcess;
  GaussianHorizontalPass gaussianPass;
  BlendPass blendPass;
  int width;
  int height;

  Tempest(num aspectRatio, int width, int height) {
    this.width = width;
    this.height = height;
    camera = new Camera(45.0, aspectRatio, 1.0, 1000.0);
    level = new CylinderLevel();
    postProcess = new PostProcess();
    gaussianPass = new GaussianHorizontalPass();
    blendPass = new BlendPass();
  }

  void setup(WebGL.RenderingContext glContext) {
    // TODO: Async setup and manager for shaders etc.
    level.setup(glContext);
    postProcess.setup(glContext, width, height);
    // TODO: Use aspect ratio size for gaussian
    gaussianPass.setup(glContext, width, height);
    blendPass.setup(glContext, width, height);
  }

  void update(double timeStep) {
    level.update(timeStep);
  }

  void render(double timeStep, WebGL.RenderingContext glContext) {
    void draw(WebGL.RenderingContext gl) {
      glContext.viewport(0, 0, width, height);
      glContext.clearColor(0.0, 0.0, 0.0, 1.0);
      glContext.clearDepth(1.0);
      glContext.clear(
          WebGL.RenderingContext.COLOR_BUFFER_BIT |
          WebGL.RenderingContext.DEPTH_BUFFER_BIT);
      level.render(gl, camera.cameraTransform);
    }
    postProcess.withBind(glContext, draw);
    gaussianPass.process(glContext, postProcess._fboTex);
    blendPass.draw(glContext, postProcess._fboTex, gaussianPass.outputTex);
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
    tempest = new Tempest(aspectRatio, width, height);
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
