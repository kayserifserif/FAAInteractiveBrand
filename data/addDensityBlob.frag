/**
 * adapted from example shader from PixelFlow
 * 
 * PixelFlow | Copyright (C) 2016 Thomas Diewald - http://thomasdiewald.com
 * 
 * A Processing/Java library for high performance GPU-Computing (GLSL).
 * MIT License: https://opensource.org/licenses/MIT
 * 
 */

#version 150

precision mediump float;
precision mediump int;

uniform vec2 wh;
uniform sampler2D tex_density_old;

uniform vec2 data_pos;
uniform float data_rad;
uniform vec4 data_density;

uniform int blend_mode;

out vec4 glFragColor;

void main() {
  
  vec2 posn = gl_FragCoord.xy / wh;
  vec4 data_src = texture(tex_density_old, posn);
  vec4 data_new = (data_src + data_density);

  float dist = distance(data_pos, gl_FragCoord.xy);
  
  if (dist < data_rad) {
  
    float dist_norm = 1.0 - clamp(dist / data_rad, 0.0, 1.0);
  
    // REPLACE
    if (blend_mode == 0) {
      glFragColor = data_new;
    }
    
    // MIX_FALLOFF
    if (blend_mode == 1) {
      float falloff = dist_norm * dist_norm;
      glFragColor = mix(data_src, data_new, falloff);
    }
    
    // MAX_FALLOFF
    if (blend_mode == 2) {
      float falloff = sqrt(sqrt(dist_norm));
      glFragColor = max(data_src, data_new * falloff);
    }

    // MAX
    if (blend_mode == 3) {
      glFragColor = max(data_src, data_new);
    }

    // NEW_RGB_OLD_A
    if (blend_mode == 4) {
      glFragColor = vec4(data_new.rgb, data_src.a);
    }

    // OLD_NEW_AVG
    if (blend_mode == 5) {
      glFragColor = (data_src + data_new) * 0.5;
    }

    // OLD_REDUCE
    if (blend_mode == 6) {
      float falloff = dist_norm * dist_norm;
      vec4 data_temp = mix(data_src, data_new, 0.99);
      glFragColor = mix(data_src, data_temp * 0.99, falloff);
    }

  } else {
    glFragColor = data_src;
  }

}