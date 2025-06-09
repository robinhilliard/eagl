#version 330

in vec3 frag_position;      // World space position
in vec3 frag_normal;        // World space normal
in vec2 frag_tex_coord;     // Texture coordinates

out vec4 out_color;

// Light properties
uniform vec3 light_position;    // World space light position
uniform vec3 light_color;       // Light color
uniform vec3 camera_position;   // World space camera position

// Material properties for white porcelain
const vec3 material_ambient = vec3(0.1, 0.1, 0.1);        // Subtle ambient
const vec3 material_diffuse = vec3(0.9, 0.9, 0.95);       // Slightly blue-white
const vec3 material_specular = vec3(1.0, 1.0, 1.0);       // Bright white highlights
const float material_shininess = 128.0;                    // Very glossy

void main() {
    // Normalize the interpolated normal
    vec3 normal = normalize(frag_normal);
    
    // Calculate light direction (same as Phong shader)
    vec3 light_dir = normalize(light_position - frag_position);
    
    // Calculate the dot product (lighting intensity)
    float dot_product = dot(normal, light_dir);
    
    // Show dot product as grayscale:
    // White = facing light (dot > 0)
    // Black = facing away (dot < 0) 
    // Gray = perpendicular (dot ≈ 0)
    float intensity = dot_product * 0.5 + 0.5;  // Map [-1,1] to [0,1]
    
    out_color = vec4(intensity, intensity, intensity, 1.0);
} 