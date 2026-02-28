#version 330 core

out vec4 FragColor;

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;

uniform vec3 lightPos;
uniform vec3 lightColor;
uniform vec3 viewPos;

struct Material {
    vec3 baseColor;
    float metallic;
    float roughness;
    vec3 emissive;
};
uniform Material material;

uniform sampler2D baseColorTexture;
uniform sampler2D metallicRoughnessTexture;
uniform sampler2D normalTexture;
uniform sampler2D emissiveTexture;
uniform bool hasBaseColorTexture;
uniform bool hasMetallicRoughnessTexture;
uniform bool hasNormalTexture;
uniform bool hasEmissiveTexture;

const float PI = 3.14159265359;

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float distributionGGX(vec3 N, vec3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0);
    float denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
    return a2 / (PI * denom * denom);
}

float geometrySchlickGGX(float NdotV, float roughness) {
    float r = (roughness + 1.0);
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
    return geometrySchlickGGX(max(dot(N, V), 0.0), roughness)
         * geometrySchlickGGX(max(dot(N, L), 0.0), roughness);
}

void main() {
    vec3 N = normalize(Normal);
    vec3 V = normalize(viewPos - FragPos);
    vec3 L = normalize(lightPos - FragPos);
    vec3 H = normalize(V + L);

    vec3 baseColor = material.baseColor;
    if (hasBaseColorTexture) {
        baseColor *= pow(texture(baseColorTexture, TexCoord).rgb, vec3(2.2));
    }

    float metallic = material.metallic;
    float roughness = material.roughness;
    if (hasMetallicRoughnessTexture) {
        vec3 mr = texture(metallicRoughnessTexture, TexCoord).rgb;
        roughness *= mr.g;
        metallic *= mr.b;
    }

    vec3 emissive = material.emissive;
    if (hasEmissiveTexture) {
        emissive *= pow(texture(emissiveTexture, TexCoord).rgb, vec3(2.2));
    }

    vec3 F0 = mix(vec3(0.04), baseColor, metallic);
    float NDF = distributionGGX(N, H, roughness);
    float G = geometrySmith(N, V, L, roughness);
    vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

    vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);
    float denom = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
    vec3 specular = (NDF * G * F) / denom;

    float NdotL = max(dot(N, L), 0.0);
    vec3 Lo = (kD * baseColor / PI + specular) * lightColor * NdotL;

    vec3 color = vec3(0.03) * baseColor + Lo + emissive;
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0/2.2));

    FragColor = vec4(color, 1.0);
}
