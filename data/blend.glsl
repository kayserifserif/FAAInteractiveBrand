#version 420

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// uniform sampler2D tex_cam;
uniform sampler2D tex_fluid;
uniform sampler2D tex_sans;
uniform sampler2D tex_serif;
uniform vec4 fluidColor;

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
  fluid = clamp(fluid, vec4(0), fluidColor); // prevent oversaturation
  vec4 mask = vec4(step(maskThresh, fluid.a)); // apply bw threshold
  vec4 sans = texture(tex_sans, texCoord);
  vec4 serif = texture(tex_serif, texCoord);
  
  // blend
  sans *= float(!bool(mask) && bool(sans.a)); // xor
  serif *= float(bool(mask) && bool(serif.a)); // intersection
  fragColor = mix(sans, fluid, fluid.a);
  fragColor = mix(fragColor, serif, serif.a);

}