precision highp float;

uniform sampler2D uSampler0;
varying vec2 vTexCoord;

void main() {
  gl_FragColor = texture2D(uSampler0, vTexCoord);
}
