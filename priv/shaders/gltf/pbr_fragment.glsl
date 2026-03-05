#version 330 core

out vec4 FragColor;

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoord;

#define MAX_LIGHTS 8

struct Light {
    int type;            // 0=directional, 1=point, 2=spot
    vec3 position;
    vec3 direction;
    vec3 color;
    float intensity;
    float range;         // 0 = infinite
    float innerConeAngle;
    float outerConeAngle;
};

uniform Light lights[MAX_LIGHTS];
uniform int numLights;
uniform vec3 ambientColor;
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
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
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

float rangeAttenuation(float distance, float range) {
    if (range <= 0.0) return 1.0 / (distance * distance);
    float ratio = distance / range;
    float clamped = clamp(1.0 - ratio * ratio * ratio * ratio, 0.0, 1.0);
    return (clamped * clamped) / (distance * distance + 0.0001);
}

float spotAttenuation(vec3 L, vec3 spotDir, float innerCone, float outerCone) {
    float cosOuter = cos(outerCone);
    float cosInner = cos(innerCone);
    float theta = dot(normalize(-L), spotDir);
    return clamp((theta - cosOuter) / max(cosInner - cosOuter, 0.0001), 0.0, 1.0);
}

void main() {
    vec3 N = normalize(Normal);
    vec3 V = normalize(viewPos - FragPos);

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
    vec3 Lo = vec3(0.0);

    for (int i = 0; i < numLights && i < MAX_LIGHTS; i++) {
        vec3 L;
        float attenuation = 1.0;

        if (lights[i].type == 0) {
            // Directional
            L = normalize(-lights[i].direction);
        } else {
            // Point or spot
            vec3 toLight = lights[i].position - FragPos;
            float dist = length(toLight);
            L = normalize(toLight);
            attenuation = rangeAttenuation(dist, lights[i].range);

            if (lights[i].type == 2) {
                attenuation *= spotAttenuation(L, lights[i].direction, lights[i].innerConeAngle, lights[i].outerConeAngle);
            }
        }

        vec3 H = normalize(V + L);
        vec3 radiance = lights[i].color * lights[i].intensity * attenuation;

        float NDF = distributionGGX(N, H, roughness);
        float G = geometrySmith(N, V, L, roughness);
        vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

        vec3 kD = (vec3(1.0) - F) * (1.0 - metallic);
        float denom = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
        vec3 spec = (NDF * G * F) / denom;

        float NdotL = max(dot(N, L), 0.0);
        Lo += (kD * baseColor / PI + spec) * radiance * NdotL;
    }

    vec3 color = ambientColor * baseColor + Lo + emissive;
    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0/2.2));

    FragColor = vec4(color, 1.0);
}
