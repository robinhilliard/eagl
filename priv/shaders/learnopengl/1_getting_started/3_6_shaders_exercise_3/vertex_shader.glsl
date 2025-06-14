#version 330 core
layout (location = 0) in vec3 aPos; // the position variable has attribute position 0

out vec3 vertexPos; // output vertex position to the fragment shader

void main()
{
    gl_Position = vec4(aPos, 1.0);
    vertexPos = aPos; // pass the vertex position to fragment shader as color
} 