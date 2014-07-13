part of tempest;

class SceneNode {
  final List<GameObject> _objects;

  SceneNode() : _objects = <GameObject>[];

  void add(GameObject gameObject) {
    _objects.add(gameObject);
  }

  void remove(GameObject gameObject) {
    _objects.remove(gameObject);
  }

  void update(double timeStep) {
    _objects.forEach((gameObject) => gameObject.update(timeStep));
  }

  void render(GraphicsContext gc, Float32List cameraTransform) {
    _objects.forEach((gameObject) => gameObject.render(gc, cameraTransform));
  }

  void cleanup() {
    _objects.removeWhere((gameObject) => gameObject.destroyed);
  }
}

class Scene {
  final List<SceneNode> _nodes;

  Scene() : _nodes = <SceneNode>[];

  void add(SceneNode node) {
    _nodes.add(node);
  }

  void remove(SceneNode node) {
    _nodes.remove(node);
  }

  void update(double timeStep) {
    _nodes.forEach((node) => node.update(timeStep));
    _nodes.forEach((node) => node.cleanup());
  }

  void render(GraphicsContext gc, Float32List cameraTransform) {
    _nodes.forEach((node) => node.render(gc, cameraTransform));
  }
}

