#version 330 core
out vec4 FragColor;

in vec2 TexCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    // Mix the two textures (original LearnOpenGL approach)
    FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
} 