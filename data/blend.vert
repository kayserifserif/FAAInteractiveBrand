#version 150

uniform mat4 transform;
uniform mat4 texMatrix;
uniform mat4 canvasScale;
uniform vec4 canvasTranslate;

in vec4 position;
in vec4 color;
in vec2 texCoord;

out vec4 vertTexCoord;

void main() {
  gl_Position = (transform * canvasScale) * (position + canvasTranslate);
  vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);
}