/**
 * 
 * adapted from example shader
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
uniform sampler2D tex_velocity_old;

uniform vec2 data_pos;
uniform float data_rad;
uniform vec2 data_velocity;

uniform int blend_mode;
const float mix_value = 0.1f;

out vec2 glFragColor;

void main() {

  vec2 posn = gl_FragCoord.xy / wh;  
  vec2 data_src = texture(tex_velocity_old, posn).xy;
  // vec2 data_new = (data_src + data_velocity);
  vec2 data_new = data_velocity;
  
  float dist = distance(data_pos, gl_FragCoord.xy);
  if (dist < data_rad) {

    float dist_norm = 1.0 - clamp(dist / data_rad, 0.0, 1.0);

    // REPLACE
    if(blend_mode == 0) {
      glFragColor = data_new;
    }
    
    // ADD
    if(blend_mode == 1) {
      data_new = data_src + data_new;
    }
    
    // MAX_MAGNITUDE
    if(blend_mode == 2) {
      data_new *= 15.0;
      if (length(data_src) > length(data_new)){
        data_new = data_src;
      } else {
        data_new = mix(data_src, data_new, mix_value);
      }
    }

    // // REPLACE
    // if(blend_mode == 0){
    //   data_new = data_ext;
    // }
    
    // // ADD
    // if(blend_mode == 1){
    //   data_new = data_src + data_ext;
    // }
    
    // // MAX_COMPONENT
    // if(blend_mode == 2){
    //   data_new = max(data_src, data_ext);
    // }
    
    // // MAX_COMPONENT_OLD_INTENSITY
    // if(blend_mode == 3){
    //   data_new = max(data_src, data_ext);
    //   data_new.a = data_src.a;
    // }
    
    // // MAX_COMPONENT_NEW_INTENSITY
    // if(blend_mode == 4){
    //   data_new = max(data_src, data_ext);
    //   data_new.a = data_ext.a;
    // }
    
    // // MIX
    // if(blend_mode == 5){
    //   data_new = mix(data_src, data_ext, mix_value);
    // }
    
    // // MIX_2
    // if(blend_mode == 6){
    //   float mix_value_ = mix_value * data_ext.a;
    //   data_new = mix(data_src, data_ext, mix_value_);
    // }

    glFragColor = data_new;

  } else {
    glFragColor = data_src;
  }
 
  // glFragColor = data_new;

}

