#version 330 core

out vec4 FragColor;

// Inputs from vertex shader
in vec3 WorldPos;
in vec3 Normal;
in vec2 TexCoord;
in vec3 VertexColor;

// glTF PBR Material Parameters (metallic-roughness workflow)
uniform vec4 baseColorFactor;   // Base color (RGBA)
uniform float metallicFactor;   // Metalness (0.0 = dielectric, 1.0 = conductor)
uniform float roughnessFactor;  // Roughness (0.0 = smooth, 1.0 = rough)
uniform vec3 emissiveFactor;    // Emissive color (HDR)

// Optional textures (set to -1 if not used)
uniform sampler2D baseColorTexture;
uniform sampler2D metallicRoughnessTexture;  // R=unused, G=roughness, B=metalness
uniform sampler2D normalTexture;
uniform sampler2D occlusionTexture;
uniform sampler2D emissiveTexture;

// Texture presence flags (1.0 if texture is bound, 0.0 if not)
uniform float hasBaseColorTexture;
uniform float hasMetallicRoughnessTexture;
uniform float hasNormalTexture;
uniform float hasOcclusionTexture;
uniform float hasEmissiveTexture;

// Lighting environment
uniform vec3 lightPosition;
uniform vec3 lightColor;
uniform vec3 cameraPos;

// Constants
const float PI = 3.14159265359;
const float EPSILON = 1e-6;

// Utility Functions
vec3 getNormalFromTexture() {
    if (hasNormalTexture > 0.5) {
        vec3 tangentNormal = texture(normalTexture, TexCoord).xyz * 2.0 - 1.0;
        // Simplified normal mapping (assumes texture coordinates provide proper tangent space)
        return normalize(Normal + tangentNormal * 0.1);
    }
    return normalize(Normal);
}

float getOcclusionFromTexture() {
    if (hasOcclusionTexture > 0.5) {
        return texture(occlusionTexture, TexCoord).r;
    }
    return 1.0;
}

// Physically Based Rendering Functions (following glTF specification)

// Normal Distribution Function (Trowbridge-Reitz/GGX)
float D_GGX(float NdotH, float roughness) {
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;
    float NdotH2 = NdotH * NdotH;
    float denom = NdotH2 * (alpha2 - 1.0) + 1.0;
    return alpha2 / (PI * denom * denom);
}

// Geometry Function (Smith's method)
float G_SchlicksmithGGX(float NdotL, float NdotV, float roughness) {
    float alpha = roughness * roughness;
    float k = alpha / 2.0;  // Direct lighting
    
    float GL = NdotL / (NdotL * (1.0 - k) + k);
    float GV = NdotV / (NdotV * (1.0 - k) + k);
    
    return GL * GV;
}

// Fresnel Function (Schlick approximation)
vec3 F_Schlick(float VdotH, vec3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - VdotH, 0.0, 1.0), 5.0);
}

// Convert metalness to F0 (following glTF spec)
vec3 getF0(vec3 baseColor, float metallic) {
    vec3 dielectricF0 = vec3(0.04);  // 4% reflectance for dielectrics
    return mix(dielectricF0, baseColor, metallic);
}

void main() {
    // Sample material properties
    vec3 baseColor = baseColorFactor.rgb;
    float metallic = metallicFactor;
    float roughness = roughnessFactor;
    vec3 emissive = emissiveFactor;
    
    // Apply base color texture
    if (hasBaseColorTexture > 0.5) {
        vec4 baseColorSample = texture(baseColorTexture, TexCoord);
        baseColor *= baseColorSample.rgb;
        // Note: Alpha channel could be used for transparency
    }
    
    // Apply vertex colors
    baseColor *= VertexColor;
    
    // Apply metallic-roughness texture
    if (hasMetallicRoughnessTexture > 0.5) {
        vec3 mrSample = texture(metallicRoughnessTexture, TexCoord).rgb;
        roughness *= mrSample.g;  // Green channel
        metallic *= mrSample.b;   // Blue channel
    }
    
    // Apply emissive texture
    if (hasEmissiveTexture > 0.5) {
        emissive *= texture(emissiveTexture, TexCoord).rgb;
    }
    
    // Clamp values to valid ranges
    roughness = clamp(roughness, 0.04, 1.0);  // Minimum roughness for numerical stability
    metallic = clamp(metallic, 0.0, 1.0);
    
    // Calculate lighting vectors
    vec3 N = getNormalFromTexture();
    vec3 V = normalize(cameraPos - WorldPos);
    vec3 L = normalize(lightPosition - WorldPos);
    vec3 H = normalize(V + L);
    
    float NdotV = max(dot(N, V), EPSILON);
    float NdotL = max(dot(N, L), EPSILON);
    float NdotH = max(dot(N, H), 0.0);
    float VdotH = max(dot(V, H), 0.0);
    
    // Material properties
    vec3 F0 = getF0(baseColor, metallic);
    vec3 diffuseColor = baseColor * (1.0 - metallic);  // Metals have no diffuse reflection
    
    // Calculate BRDF components
    float D = D_GGX(NdotH, roughness);
    float G = G_SchlicksmithGGX(NdotL, NdotV, roughness);
    vec3 F = F_Schlick(VdotH, F0);
    
    // Specular BRDF
    vec3 specular = (D * G * F) / (4.0 * NdotV * NdotL + EPSILON);
    
    // Diffuse BRDF (Lambertian)
    vec3 diffuse = diffuseColor / PI;
    
    // Energy conservation: diffuse component is reduced by specular contribution
    vec3 kS = F;  // Specular contribution
    vec3 kD = vec3(1.0) - kS;  // Diffuse contribution
    kD *= 1.0 - metallic;  // Metals have no diffuse component
    
    // Final radiance
    vec3 radiance = lightColor;  // Simplified: assume light intensity is in lightColor
    vec3 Lo = (kD * diffuse + specular) * radiance * NdotL;
    
    // Simple ambient lighting (should be IBL in a full implementation)
    vec3 ambient = vec3(0.03) * baseColor;
    
    // Apply ambient occlusion
    float occlusion = getOcclusionFromTexture();
    ambient *= occlusion;
    
    // Add emissive contribution
    vec3 color = ambient + Lo + emissive;
    
    // Simple tone mapping (Reinhard)
    color = color / (color + vec3(1.0));
    
    // Gamma correction
    color = pow(color, vec3(1.0/2.2));
    
    FragColor = vec4(color, baseColorFactor.a);
} 