#version 330

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// uniform sampler2D tex_cam;
uniform sampler2D tex_fluid;
uniform sampler2D tex_sans;
uniform sampler2D tex_serif;

in vec4 vertColor;
in vec4 vertTexCoord;

out vec4 fragColor;

// float camTint = 0.5;
float maskThresh = 0.6;

void main() {
  // coordinates
  vec2 texCoord = vertTexCoord.st;
  vec2 invTexCoord = vec2(vertTexCoord.s, 1.0 - vertTexCoord.t); // invert y
  // textures
  // vec4 cam = texture(tex_cam, texCoord);
  // cam = vec4(cam.rgb, camTint); // tint cam
  vec4 fluid = texture(tex_fluid, invTexCoord);
  vec4 mask = step(maskThresh, texture(tex_fluid, invTexCoord)); // apply bw threshold
  vec4 sans = texture(tex_sans, texCoord);
  vec4 serif = texture(tex_serif, texCoord);
  // blend
  sans = step(1.0 - mask.a, sans); // inverted mask
  serif = step(mask.a, serif); // mask
  vec4 color = fluid + sans * serif;
  fragColor = color;
}