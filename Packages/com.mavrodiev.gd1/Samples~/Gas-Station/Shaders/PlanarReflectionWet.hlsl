// Gas Station: the wet ground's planar reflection. PlanarReflection.cs renders the scene, fog included, from a camera
// mirrored below the forecourt into _PlanarReflectionTex; its image is the main view flipped vertically, so a ground
// pixel reads it at (u, 1 - v). The surface's normal bends the lookup, and roughness smears it vertically into the long
// streaks wet asphalt makes (HDRP's ray-traced reflections gathered the fog along each reflected ray; SSR cannot).
#ifndef GAS_STATION_PLANAR_REFLECTION_WET_INCLUDED
#define GAS_STATION_PLANAR_REFLECTION_WET_INCLUDED

TEXTURE2D(_PlanarReflectionTex); SAMPLER(sampler_PlanarReflectionTex);

half3 WetPlanarReflection(InputData inputData, half smoothness)
{
    float2 uv = inputData.normalizedScreenSpaceUV;
    uv.y = 1.0 - uv.y;
    uv += inputData.normalWS.xz * _PlanarDistortion;
    half rough = 1.0 - smoothness;
    float stretch = _PlanarStretch * rough * rough * 4.0;      // smooth puddles stay sharp, rough concrete streaks
    half3 sum = 0;
    UNITY_UNROLL
    for (int i = 0; i < 9; i++)
    {
        float t = (i - 4) / 4.0;                                  // -1..1 along the vertical
        half w = 1.0 - abs(t) * 0.75;
        sum += SAMPLE_TEXTURE2D_LOD(_PlanarReflectionTex, sampler_PlanarReflectionTex, uv + float2(0, t * stretch), rough * 4.0).rgb * w;
    }
    sum /= 6.0;                                                   // the weights' total (1 + 2 x (0.8125 + 0.625 + 0.4375 + 0.25))
    half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    half fresnel = 0.04 + 0.96 * pow(1.0 - NdotV, 5.0);
    return sum * fresnel * smoothness * _PlanarStrength;
}
#endif
