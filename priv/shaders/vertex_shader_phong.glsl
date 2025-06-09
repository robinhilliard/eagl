#version 330

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 tex_coord;
layout(location = 2) in vec3 normal;

// Outputs to fragment shader
out vec3 frag_position;     // World space position
out vec3 frag_normal;       // World space normal
out vec2 frag_tex_coord;    // Texture coordinates

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    // Transform position to world space
    vec4 world_position = model * vec4(position, 1.0);
    frag_position = world_position.xyz;
    
    // Transform normal to world space (assuming uniform scaling)
    // For non-uniform scaling, use transpose(inverse(mat3(model)))
    // Testing: Remove flip to see if clockwise_winding: true fixes normals
    frag_normal = normalize(mat3(model) * normal);
    
    // Pass through texture coordinates
    frag_tex_coord = tex_coord;
    
    // Final position in clip space
    gl_Position = projection * view * world_position;
} 