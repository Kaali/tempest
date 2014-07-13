precision highp float;

varying vec2 vTexCoord;

void main(void) {
  float width = 0.04;
  float edgeX = (vTexCoord.x < width || vTexCoord.x > 1.0 - width) ? 1.0 : 0.0;
  float edgeY = (vTexCoord.y < width || vTexCoord.y > 1.0 - width) ? 1.0 : 0.0;
  float edge = min(1.0, edgeX + edgeY);
  if (edge == 1.0) {
    // Edges
    gl_FragColor = vec4(0.2, 0.3, 1.0 * edge, 1.0);
  } else {
    // Inner
    gl_FragColor = vec4(0.025, 0.025, 0.05, 1.0);
  }

  // fog test just for kicks
  float fogNear = 0.1;
  float fogFar = 4.0;
  float depth = gl_FragCoord.z / gl_FragCoord.w;
  float fog = smoothstep(fogNear, fogFar, depth);
  gl_FragColor = mix(gl_FragColor, vec4(0.0, 0.0, 0.0, gl_FragColor.w), fog);
}
