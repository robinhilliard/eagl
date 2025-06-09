#version 150

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
    
    // Calculate light direction
    vec3 light_dir = normalize(light_position - frag_position);
    
    // Calculate view direction
    vec3 view_dir = normalize(camera_position - frag_position);
    
    // Calculate reflection direction for specular
    vec3 reflect_dir = reflect(-light_dir, normal);
    
    // Ambient component
    vec3 ambient = material_ambient * light_color;
    
    // Diffuse component (Lambertian)
    float diff = max(dot(normal, light_dir), 0.0);
    vec3 diffuse = diff * material_diffuse * light_color;
    
    // Specular component (Phong)
    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), material_shininess);
    vec3 specular = spec * material_specular * light_color;
    
    // Combine all components
    vec3 result = ambient + diffuse + specular;
    
    out_color = vec4(result, 1.0);
} 