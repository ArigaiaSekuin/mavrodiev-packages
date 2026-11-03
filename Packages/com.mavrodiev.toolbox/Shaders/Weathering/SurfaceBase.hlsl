// SurfaceBase.hlsl — shared by the Surface shaders (Wet-Puddles, Snow-Top, Damp-Base).
// The base material is read here exactly like URP Lit reads it (Base Map, metallic-smoothness map,
// normal map, occlusion map). Each .shader then writes MixLayer(): the layer it puts on top, placed by a mask.
// Before including this file, the shader declares its CBUFFER (with the base properties below) and its own textures.
#ifndef SURFACE_BASE_INCLUDED
#define SURFACE_BASE_INCLUDED

TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_NoiseMap);           SAMPLER(sampler_NoiseMap);

// What MixLayer() gets to decide where its layer goes.
struct MixInput
{
    float2 uv;              // the base UV, with the Base Map's Tiling and Offset applied
    float2 uv0;             // the mesh's own UV (ProBuilder: 1 unit = 1 m)
    float3 positionWS;      // world position of the pixel
    half3  normalWS;        // the mesh's world-space normal (before the normal map)
    half3x3 tangentToWorld; // to bring a tangent-space normal into world space
};

// The base material, as URP Lit reads it.
void SampleBaseSurface(float2 uv, out SurfaceData s)
{
    s = (SurfaceData)0;
    half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half4 mg = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
    s.albedo = albedo.rgb * _BaseColor.rgb;
    s.alpha = 1.0;
    s.metallic = mg.r * _Metallic;          // map R = metallic
    s.smoothness = mg.a * _Smoothness;      // map A = smoothness
    s.specular = half3(0, 0, 0);
    s.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    s.occlusion = LerpWhiteTo(SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g, _OcclusionStrength);
    s.emission = half3(0, 0, 0);
}

// Small helpers for the layers
float SurfHash(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }
half3 SurfFlatten(half3 normalTS, half amount) { return normalize(lerp(normalTS, half3(0, 0, 1), amount)); }

#endif
