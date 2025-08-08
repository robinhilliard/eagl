#version 150

in vec3 position;
in vec3 normal;
in vec2 tex_coord;

out vec3 frag_color;
out vec2 frag_tex_coord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
  gl_Position = projection * view * model * vec4(position, 1.0);
  frag_color = vec3(0.0, 0.0, 1.0);  // Blue
  frag_tex_coord = tex_coord;
}
