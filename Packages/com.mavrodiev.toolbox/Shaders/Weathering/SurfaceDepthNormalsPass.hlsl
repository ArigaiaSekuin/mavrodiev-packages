// SurfaceDepthNormalsPass.hlsl — writes the mixed surface's normal (and its smoothness, for screen-space
// reflections) into the camera normals texture. Based on URP's LitDepthNormalsPass.hlsl (URP 17.6).
// SSAO and SSR read this texture, so a puddle's flat normal and high smoothness must be written here too.
#ifndef SURFACE_DEPTH_NORMALS_PASS_INCLUDED
#define SURFACE_DEPTH_NORMALS_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float3 normal       : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS  : SV_POSITION;
    float4 uv          : TEXCOORD1;   // xy: base UV, zw: mesh UV
    half3 normalWS     : TEXCOORD2;
    half4 tangentWS    : TEXCOORD4;
    float3 positionWS  : TEXCOORD5;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings SurfaceDepthNormalsVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.uv = float4(TRANSFORM_TEX(input.texcoord, _BaseMap), input.texcoord);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;
    output.normalWS = half3(normalInput.normalWS);
    float sign = input.tangentOS.w * float(GetOddNegativeScale());
    output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
    return output;
}

void SurfaceDepthNormalsFragment(
    Varyings input
    , out half4 outNormalWS : SV_Target0
#ifdef _WRITE_RENDERING_LAYERS
    , out uint outRenderingLayers : SV_Target1
#endif
)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData s;
    SampleBaseSurface(input.uv.xy, s);
    float sgn = input.tangentWS.w;
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
    MixInput m;
    m.uv = input.uv.xy;
    m.uv0 = input.uv.zw;
    m.positionWS = input.positionWS;
    m.normalWS = normalize(input.normalWS);
    m.tangentToWorld = tangentToWorld;
    MixLayer(m, s);

    #if defined(_GBUFFER_NORMALS_OCT)
        float3 normalWS = normalize(input.normalWS);
        float2 octNormalWS = PackNormalOctQuadEncode(normalWS);
        float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
        half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
        outNormalWS = half4(packedNormalWS, 0.0);
    #else
        float3 normalWS = TransformTangentToWorld(s.normalTS, tangentToWorld);
        outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
    #endif

    #if defined(_WRITE_SMOOTHNESS) && !defined(_SCREENSPACEREFLECTIONS_OFF)
        outNormalWS.a = s.smoothness;
    #endif

    #ifdef _WRITE_RENDERING_LAYERS
        outRenderingLayers = EncodeMeshRenderingLayer();
    #endif
}

#endif
