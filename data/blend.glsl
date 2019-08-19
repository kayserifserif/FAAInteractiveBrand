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
  bvec4 mask = bvec4(step(maskThresh, fluid)); // apply bw threshold
  bvec4 sans = bvec4(texture(tex_sans, texCoord));
  bvec4 serif = bvec4(texture(tex_serif, texCoord));
  
  // blend
  sans = !mask && sans; // xor
  serif = mask && serif; // intersection
  fragColor = vec4(sans) + fluid - vec4(serif);

}