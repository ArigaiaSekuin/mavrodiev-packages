// Planar-Reflection.hlsl
// Toolbox, Shaders/Common.
// Generalised from the Gas-Station's PlanarReflectionWet.hlsl (Petar's, URP-Tests): the same lookup, with its
// settings passed in instead of read from one material.
//
// PlanarReflection.cs renders the scene from a camera mirrored below the floor into _PlanarReflectionTex.
// That camera is a real one (not a flipped matrix), so its image is the main view flipped vertically:
// a floor pixel reads it at (u, 1 - v). The surface's normal bends the lookup, and roughness smears it
// vertically into the long streaks wet floors make. Where no planar reflection is active the script sets the
// texture to black, so this adds nothing.
// Include after URP's Lighting.hlsl (it needs InputData).

#ifndef MAVRODIEV_PLANAR_REFLECTION_INCLUDED
#define MAVRODIEV_PLANAR_REFLECTION_INCLUDED

TEXTURE2D(_PlanarReflectionTex); SAMPLER(sampler_PlanarReflectionTex);

// smoothness: the surface's; distortion: how far the normal bends the lookup; stretch: the vertical smear at full
// roughness (in screen units); strength: a multiplier on the result.
half3 PlanarReflection(InputData inputData, half smoothness, half distortion, half stretch, half strength)
{
    float2 uv = inputData.normalizedScreenSpaceUV;
    uv.y = 1.0 - uv.y;
    uv += inputData.normalWS.xz * distortion;
    half rough = 1.0 - smoothness;
    float smear = stretch * rough * rough * 4.0;                  // smooth puddles stay sharp, rough surfaces streak
    half3 sum = 0;
    UNITY_UNROLL
    for (int i = 0; i < 9; i++)
    {
        float t = (i - 4) / 4.0;                                  // -1..1 along the vertical
        half w = 1.0 - abs(t) * 0.75;
        sum += SAMPLE_TEXTURE2D_LOD(_PlanarReflectionTex, sampler_PlanarReflectionTex, uv + float2(0, t * smear), rough * 4.0).rgb * w;
    }
    sum /= 5.25;                                                  // the weights' total: 1 + 2 x (0.8125 + 0.625 + 0.4375 + 0.25)
                                                                  // (the Gas-Station copy divides by 6, so its Strength values read ~14% darker)
    half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    half fresnel = 0.04 + 0.96 * pow(1.0 - NdotV, 5.0);           // more reflection at grazing angles (Schlick)
    return sum * fresnel * smoothness * strength;
}

#endif
