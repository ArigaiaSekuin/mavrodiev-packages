// Library-Lighting.hlsl
// Shared by the ForwardLit pass of the Library shaders.
// URP's Lit shader prepares the same information before it computes the light on a pixel.
// Here it is collected in one function, so each shader can stay short and show only its own idea.

#ifndef LIBRARY_LIGHTING_INCLUDED
#define LIBRARY_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// Everything URP's lighting functions need to know about one pixel:
// where it is, which way it faces, where the camera is, its shadows, its fog and the ambient light.
InputData LibraryInputData(float3 positionWS, float3 normalWS, float4 positionCS, half fogFactor)
{
    InputData inputData = (InputData)0;
    inputData.positionWS = positionWS;
    inputData.positionCS = positionCS;
    inputData.normalWS = NormalizeNormalPerPixel(normalWS);
    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(positionWS);
    inputData.shadowCoord = TransformWorldToShadowCoord(positionWS);          // where this pixel falls in the main light's shadow map
    inputData.fogCoord = InitializeInputDataFog(float4(positionWS, 1.0), fogFactor);
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(positionCS); // 0..1 across the screen (used by Forward+, SSAO, SSR)
    inputData.bakedGI = SampleSH(inputData.normalWS);                           // the ambient light from the Lighting window (sky, gradient or colour)
    inputData.shadowMask = half4(1, 1, 1, 1);
    return inputData;
}

// A surface with only the values a shader sets; everything else neutral.
SurfaceData LibrarySurface(half3 albedo, half smoothness, half3 emission)
{
    SurfaceData s = (SurfaceData)0;
    s.albedo = albedo;
    s.metallic = 0;
    s.specular = 0;
    s.smoothness = smoothness;
    s.normalTS = half3(0, 0, 1);
    s.emission = emission;
    s.occlusion = 1;
    s.alpha = 1;
    return s;
}

// How much a surface reflects instead of letting light through, by viewing angle (Schlick's Fresnel).
// Looking straight at glass or water: about 4% reflected. Looking along it: almost everything reflected.
half LibraryFresnel(half3 normalWS, half3 viewDirWS, half f0)
{
    half cosine = saturate(dot(normalWS, viewDirWS));
    return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

#endif
