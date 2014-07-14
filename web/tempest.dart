// Copyright (c) 2014, Väinö Järvelä.

library tempest;

import 'dart:html';
import 'dart:web_gl' as WebGL;
import 'dart:async';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:vector_math/vector_math.dart';

part 'camera.dart';
part 'shader.dart';
part 'vertex_uv_buffer.dart';
part 'level.dart';
part 'post_process.dart';
part 'action.dart';
part 'weapons.dart';
part 'scene.dart';
part 'graphics.dart';

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

  void setup(GraphicsContext gc);
  void update(double timeStep);
  void render(GraphicsContext gc, Float32List cameraTransform);
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

    camera.eyePosition = _cameraPosition();
    level.setPlayerPosition(gameState.playerPosition);
  }

  void setup(GraphicsContext gc) {
    // TODO: Async setup and manager for shaders etc.
    level.setup(gc);
    captureProcess.setup(gc, width, height);
    // TODO: Use aspect ratio size for gaussian
    gaussianPass.setup(gc, width, height);
    blendPass.setup(gc, width, height);
    scanlinePass.setup(gc, width, height);
  }

  Vector3 _playerPosition() => level.playerFacePosition(gameState.playerPosition).clone();

  Vector3 _cameraPosition() {
    var facePos = _playerPosition();
    return new Vector3(
      facePos.x * 0.2, facePos.y * 0.2, camera.eyePosition.z);
  }

  void _moveCameraToPlayerPos() {
    moveAction.moveTo(camera.eyePosition.clone(), _cameraPosition(), 0.08);
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
        var pos = _playerPosition();
        var bullet = new Bullet.pooled(new Vector3(pos.x, pos.y, -1.0), new Vector3(0.0, 0.0, -1.0));
        if (bullet != null) {
          bulletNode.add(bullet);
        }
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

  void render(double timeStep, GraphicsContext gc) {
    captureProcess.withBind(gc, (gc) {
      gc.clear();
      scene.render(gc, camera.cameraTransform);
    });
    gaussianPass.process(gc, captureProcess.outputTex);
    blendPass.process(gc, captureProcess.outputTex, gaussianPass.outputTex);
    scanlinePass.draw(gc, blendPass.outputTex);
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
  GraphicsContext gc;
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
    gc = new GraphicsContext(glContext, canvas.width, canvas.height);

    Future f = setupAssets();
    f.then((_) {
      bind();
      requestRAF();
    });
  }

  Future<Shader> loadShader(String name, String vertexShaderUri,
                            String fragmentShaderUri, List<String> uniforms,
                            List<String> attributes) {
    return HttpRequest.getString(vertexShaderUri).then((vertexShader) {
      return HttpRequest.getString(fragmentShaderUri).then((fragmentShader) {
        return gc.createShader(name, vertexShader, fragmentShader, uniforms,
            attributes);
      });
    });
  }

  Future loadShadersFromJson(String name) {
    List<String> parseList(dynamic templates, List<String> fields) {
      var items = new List<String>();
      for (String field in fields) {
        if (field[0] == '\$') {
          items.addAll(templates[field.substring(1)]);
        } else {
          items.add(field);
        }
      }
      return items;
    }

    return HttpRequest.getString(name).then((json) {
      var data = JSON.decode(json);
      var shaders = new List<Future<Shader>>();
      for (var shaderInfo in data['shaders']) {
        var name = shaderInfo['name'];
        var vertex = shaderInfo['vertex'];
        var fragment = shaderInfo['fragment'];
        var uniforms = parseList(data['templates'], shaderInfo['uniforms']);
        var attributes = parseList(data['templates'], shaderInfo['attributes']);
        shaders.add(loadShader(name, vertex, fragment, uniforms, attributes));
      }
      return Future.wait(shaders, eagerError: true).then((_) => null);
    });
  }

  Future setupAssets() {
    return loadShadersFromJson('shaders.json').then((_) {
      tempest = new Tempest(aspectRatio, width, height);
      tempest.setup(gc);
    });
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
    tempest.render(timeStep, gc);
  }

  void requestRAF() {
    window.requestAnimationFrame(rAF);
  }
}

TempestApplication application = new TempestApplication();

void main() {
  application.startup('#container');
}
