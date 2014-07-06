part of tempest;

class Camera {
  Vector3 eyePosition;
  Vector3 upDirection;
  Vector3 lookAtPosition;

  double zNear;
  double zFar;
  double aspectRatio;
  double fovY;

  Camera(double fovYDeg, double this.aspectRatio, double this.zNear,
         double this.zFar)
      : fovY = fovYDeg * radians2degrees,
        eyePosition = new Vector3(0.0, 0.0, 0.0),
        upDirection = new Vector3(0.0, 1.0, 0.0),
        lookAtPosition = new Vector3(0.0, 0.0, -50.0);

  Matrix4 get projectionMatrix =>
    makePerspectiveMatrix(fovY, aspectRatio, zNear, zFar);

  Matrix4 get lookAtMatrix =>
    makeViewMatrix(eyePosition, lookAtPosition, upDirection);

  Float32List get cameraTransform {
    // TODO: Cache
    var cameraMatrix = projectionMatrix;
    cameraMatrix.multiply(lookAtMatrix);

    var cameraTransform = new Float32List(16);
    cameraMatrix.copyIntoArray(cameraTransform, 0);
    return cameraTransform;
  }
}
