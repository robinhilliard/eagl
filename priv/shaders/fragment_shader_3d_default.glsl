#version 150

in vec2 frag_tex_coord;
in vec3 frag_color;

out vec4 out_color;

void main() {
    out_color = vec4(frag_color, 1.0);
}