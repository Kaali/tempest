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
part 'post_process.dart';
part 'action.dart';
part 'weapons.dart';
part 'scene.dart';

double timestamp() {
  if (window.performance != null) {
    return window.performance.now();
  } else {
    return new DateTime.now().millisecondsSinceEpoch.toDouble();
  }
}

abstract class GameObject {
  bool destroyed;

  GameObject() : destroyed = false;

  void setup(WebGL.RenderingContext gl);
  void update(double timeStep);
  void render(WebGL.RenderingContext gl, Float32List cameraTransform);
}

class GameState {
  int playerPosition = 0;
}

class InputState {
  bool moveLeft = false;
  bool moveRight = false;
  bool fire = false;

  InputState clone() {
    var inputState = new InputState();
    inputState.moveLeft = moveLeft;
    inputState.moveRight = moveRight;
    inputState.fire = fire;
    return inputState;
  }
}

class Tempest {
  Scene scene;
  SceneNode bulletNode;
  SceneNode levelNode;
  Camera camera;
  Level level;
  CaptureProcess captureProcess;
  GaussianHorizontalPass gaussianPass;
  BlendPass blendPass;
  ScanlinePass scanlinePass;
  GameState gameState;
  InputState inputState;
  int width;
  int height;
  ActionManager actionManager;
  MoveAction moveAction;
  double sinceLastFire;

  // Keys
  static const int KEY_LEFT = 37;
  static const int KEY_RIGHT = 39;
  static const int KEY_FIRE = 32;

  static const double FIRE_DELAY = 0.08;

  Tempest(num aspectRatio, int this.width, int this.height)
      : gameState = new GameState(),
        inputState = new InputState(),
        camera = new Camera(45.0, aspectRatio, 0.1, 1000.0),
        level = new CylinderLevel(),
        captureProcess = new CaptureProcess(),
        gaussianPass = new GaussianHorizontalPass(),
        blendPass = new BlendPass(),
        scanlinePass = new ScanlinePass(),
        actionManager = new ActionManager(),
        sinceLastFire = 0.0 {
    moveAction = new MoveAction(actionManager);

    scene = new Scene();
    levelNode = new SceneNode();
    levelNode.add(level);
    scene.add(levelNode);

    bulletNode = new SceneNode();
    scene.add(bulletNode);
  }

  void setup(WebGL.RenderingContext glContext) {
    // TODO: Async setup and manager for shaders etc.
    level.setup(glContext);
    captureProcess.setup(glContext, width, height);
    // TODO: Use aspect ratio size for gaussian
    gaussianPass.setup(glContext, width, height);
    blendPass.setup(glContext, width, height);
    scanlinePass.setup(glContext, width, height);
  }

  Vector2 _playerPosition() => level.playerFacePosition(gameState.playerPosition).clone();

  void _moveCameraToPlayerPos() {
    var facePos = _playerPosition();
    var newEyePos = new Vector3(
        facePos.x * 0.2, facePos.y * 0.2, camera.eyePosition.z);
    moveAction.moveTo(camera.eyePosition.clone(), newEyePos, 0.08);
  }

  void update(double timeStep) {
    var frameInputState = inputState.clone();
    if (!moveAction.isRunning) {
      if (inputState.moveLeft) {
        gameState.playerPosition = level.setPlayerPosition(gameState.playerPosition - 1);
        _moveCameraToPlayerPos();
      } else if (inputState.moveRight) {
        gameState.playerPosition = level.setPlayerPosition(gameState.playerPosition + 1);
        _moveCameraToPlayerPos();
      }
      if (inputState.fire && sinceLastFire >= FIRE_DELAY) {
        // TODO: Fix setup system, cannot fire bullet because it has not been set-up
        // TODO: Player position needs to have z-coordinate too
        var pos = _playerPosition();
        bulletNode.add(new Bullet(new Vector3(pos.x, pos.y, -1.0), new Vector3(0.0, 0.0, -1.0)));
        sinceLastFire = 0.0;
      }
    }
    sinceLastFire += timeStep;

    actionManager.update(timeStep);

    // TODO: Replace with onTick/onUpdate callack
    if (moveAction.current != null && moveAction.current != camera.eyePosition) {
      camera.eyePosition = moveAction.current;
    }
    scene.update(timeStep);
  }

  void render(double timeStep, WebGL.RenderingContext glContext) {
    void draw(WebGL.RenderingContext gl) {
      glContext.viewport(0, 0, width, height);
      glContext.clearColor(0.0, 0.0, 0.0, 1.0);
      glContext.clearDepth(1.0);
      glContext.clear(
          WebGL.RenderingContext.COLOR_BUFFER_BIT |
          WebGL.RenderingContext.DEPTH_BUFFER_BIT);
      var cameraTransform = camera.cameraTransform;

      // TODO: Depth buffer doesn't work without extensions in WebGL 1.x do a scene sort
      scene.render(gl, cameraTransform);
    }
    captureProcess.withBind(glContext, draw);
    gaussianPass.process(glContext, captureProcess._fboTex);
    blendPass.process(glContext, captureProcess._fboTex, gaussianPass.outputTex);
    scanlinePass.draw(glContext, blendPass.outputTex);
  }

  void onKeyDown(KeyboardEvent event) {
    switch (event.keyCode) {
      case KEY_LEFT:
        inputState.moveLeft = true;
        break;
      case KEY_RIGHT:
        inputState.moveRight = true;
        break;
      case KEY_FIRE:
        inputState.fire = true;
        break;
      default:
        break;
    }
  }

  void onKeyUp(KeyboardEvent event) {
    switch (event.keyCode) {
      case KEY_LEFT:
        inputState.moveLeft = false;
        break;
      case KEY_RIGHT:
        inputState.moveRight = false;
        break;
      case KEY_FIRE:
        inputState.fire = false;
        break;
      default:
        break;
    }
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
