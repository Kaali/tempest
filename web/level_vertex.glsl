attribute vec3 aPosition;
attribute vec2 aTexCoord;
uniform mat4 uCameraTransform;
uniform mat4 uModelTransform;
uniform int uActive;

varying vec2 vTexCoord;
varying float vActive;

void main(void) {
  vec4 pos = uCameraTransform * uModelTransform * vec4(aPosition, 1.0);
  gl_Position = pos;
  vTexCoord = aTexCoord;
  vActive = uActive == 1 ? 1.0 : 0.0;
}
