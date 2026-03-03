#version 330 core

out vec4 FragColor;

uniform float nodeId;

void main() {
    float id = nodeId;
    float r = mod(id, 256.0) / 255.0;
    float g = mod(floor(id / 256.0), 256.0) / 255.0;
    float b = mod(floor(id / 65536.0), 256.0) / 255.0;
    FragColor = vec4(r, g, b, 1.0);
}
