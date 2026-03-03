#version 330 core

out vec4 FragColor;

in vec2 TexCoord;

uniform sampler2D pickTexture;

// Decode node ID from pick buffer (r + g*256 + b*65536) and map to distinct colors
vec3 idToColor(float id) {
    float hue = mod(id * 0.618033988749895, 1.0);  // golden ratio for distinct hues
    float h = hue * 6.0;
    float x = 1.0 - abs(mod(h, 2.0) - 1.0);
    if (h < 1.0) return vec3(1.0, x, 0.0);
    if (h < 2.0) return vec3(x, 1.0, 0.0);
    if (h < 3.0) return vec3(0.0, 1.0, x);
    if (h < 4.0) return vec3(0.0, x, 1.0);
    if (h < 5.0) return vec3(x, 0.0, 1.0);
    return vec3(1.0, 0.0, x);
}

void main() {
    vec4 c = texture(pickTexture, TexCoord);
    float id = c.r * 255.0 + c.g * 255.0 * 256.0 + c.b * 255.0 * 65536.0;
    if (id < 0.5) {
        FragColor = vec4(0.0, 0.0, 0.0, 1.0);  // no hit
    } else {
        FragColor = vec4(idToColor(id), 1.0);
    }
}
