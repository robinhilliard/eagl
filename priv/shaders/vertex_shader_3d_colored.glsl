#version 150

in vec3 position;
in vec3 normal;
in vec2 tex_coord;

out vec3 frag_color;
out vec2 frag_tex_coord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 objectColor;

void main() {
  gl_Position = projection * view * model * vec4(position, 1.0);
  // Use color uniform, with fallback to white if not set
  frag_color = objectColor;
  frag_tex_coord = tex_coord;
}
