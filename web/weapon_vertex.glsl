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
