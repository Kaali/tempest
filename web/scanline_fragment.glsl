precision highp float;

uniform float uSize;

uniform sampler2D uSampler0;
varying vec2 vTexCoord;

void main() {
  gl_FragColor = texture2D(uSampler0, vTexCoord) * clamp(sin(vTexCoord.y * uSize), 0.7, 1.0);
  gl_FragColor.w = 1.0;
}
