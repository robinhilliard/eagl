#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;

void main()
{
    // Sample texture and mix with vertex color to show center crop effect
    FragColor = texture(ourTexture, TexCoord) * vec4(ourColor, 1.0);
} 