#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// uniform vec2 u_resolution;
uniform sampler2D tex_cam;
uniform sampler2D tex_fluid;
uniform sampler2D tex_sans;
uniform sampler2D tex_serif;

varying vec4 vertColor;
varying vec4 vertTexCoord;

float camTint = 0.5;
float maskThresh = 0.6;

void main() {
  vec4 cam = texture2D(tex_cam, vertTexCoord.st);
  cam = vec4(cam.rgb, camTint); // tint cam
  vec4 fluid = texture2D(tex_fluid, vec2(vertTexCoord.s, 1.0 - vertTexCoord.t)); // invert y
  vec4 mask = step(maskThresh, texture2D(tex_fluid, vertTexCoord.st)); // apply bw threshold
  vec4 sans = texture2D(tex_sans, vertTexCoord.st);
  sans = step((1.0 - mask.a), sans); // inverted mask
  vec4 serif = texture2D(tex_serif, vertTexCoord.st);
  serif = step(mask.a, serif); // mask
  vec4 color = fluid + sans * serif;
  gl_FragColor = color;
}