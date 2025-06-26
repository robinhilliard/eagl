#version 330 core

// Standard vertex attributes (matching EAGL.Buffer conventions)
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aTexCoord;
layout (location = 3) in vec3 aNormal;

// Outputs to fragment shader
out vec3 WorldPos;
out vec3 Normal;
out vec2 TexCoord;
out vec3 VertexColor;

// Standard transformation matrices
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    // Transform position to world space
    vec4 worldPos = model * vec4(aPos, 1.0);
    WorldPos = worldPos.xyz;
    
    // Transform normal to world space (for non-uniform scaling, use normal matrix)
    Normal = normalize(mat3(model) * aNormal);
    
    // Pass through texture coordinates and vertex colors
    TexCoord = aTexCoord;
    VertexColor = aColor;
    
    // Final position in clip space
    gl_Position = projection * view * worldPos;
} 