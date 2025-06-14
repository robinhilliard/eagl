#version 330 core
out vec4 FragColor;
in vec3 vertexPos; // receive interpolated vertex position from vertex shader

void main()
{
    // Exercise 3 solution: Use vertex position as color
    // Note: negative values will be clamped to 0.0, making some areas black
    FragColor = vec4(vertexPos, 1.0);
} 