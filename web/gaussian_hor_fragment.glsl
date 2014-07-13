// Adapted from:
// https://web.archive.org/web/20121003045153/http://devmaster.net/posts/3100/shader-effects-glow-and-bloom
precision highp float;

uniform float uSize;
uniform int uBlurAmount;
uniform float uBlurScale;
uniform float uBlurStrength;

uniform sampler2D uSampler0;
varying vec2 vTexCoord;

float Gaussian (float x, float deviation) {
  return (1.0 / sqrt(2.0 * 3.141592 * deviation)) * exp(-((x * x) / (2.0 * deviation)));
}

void main() {
  float halfBlur = float(uBlurAmount) * 0.5;
  vec4 color = vec4(0.0);
  vec4 texColor = vec4(0.0);

  float deviation = halfBlur * 0.35;
  deviation *= deviation;
  float strength = 1.0 - uBlurStrength;

  for (int i = 0; i < 10; ++i) {
    if (i >= uBlurAmount) break;
    float offset = float(i) - halfBlur;
    texColor = texture2D(uSampler0, vTexCoord + vec2(offset * uSize * uBlurScale, 0.0)) *
      Gaussian(offset * strength, deviation);
    color += texColor;
  }

  gl_FragColor = clamp(color, 0.0, 1.0);
  gl_FragColor.w = 1.0;
}
