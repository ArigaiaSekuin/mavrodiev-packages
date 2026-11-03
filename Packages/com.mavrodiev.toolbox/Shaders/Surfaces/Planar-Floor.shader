// Planar Floor - a smooth floor that shows a planar reflection (Surfaces family).
// What it reads that the Lit shader does not:
//   _PlanarReflectionTex  -> the picture a PlanarReflection component renders from a camera mirrored below the floor
//                            (Runtime/PlanarReflection.cs); black where none is active, so it adds nothing
//   the world position     -> the base map and the normal map are laid in metres on X and Z, so no UVs are needed
// Everything else (lights, shadows, SSAO, reflection probes, screen space reflections, fog) is URP's own PBR lighting.
// Meant for horizontal surfaces. Put the floor on a layer the PlanarReflection does not render (default: Water),
// so the mirrored camera below it is not blocked by the floor itself.

Shader "Mavrodiev/Surfaces/Planar-Floor"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.15, 0.15, 0.16, 1)
        [NoScaleOffset] _BaseMap ("Base Map", 2D) = "white" {}
        [Normal][NoScaleOffset] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0, 2)) = 0.5
        _TileSize ("Tile Size (m)", Float) = 2
        _Smoothness ("Smoothness", Range(0, 1)) = 0.9
        [Header(Planar Reflection)]
        _PlanarStrength ("Planar Strength", Range(0, 4)) = 1
        _PlanarDistortion ("Distortion by the normal", Range(0, 0.2)) = 0.03
        _PlanarStretch ("Vertical Stretch at full roughness", Range(0, 0.5)) = 0.12
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _NormalStrength;
            float _TileSize;
            half _Smoothness;
            half _PlanarStrength;
            half _PlanarDistortion;
            half _PlanarStretch;
        CBUFFER_END

        TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
        TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

        float2 FloorUV(float3 positionWS) { return positionWS.xz / max(_TileSize, 0.01); }

        // The normal map laid on the floor: its X and Y along the world's X and Z (as in Water).
        float3 FloorNormal(float3 positionWS, float3 flatNormalWS)
        {
            half3 n = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, FloorUV(positionWS)), _NormalStrength);
            float3 tangent = normalize(float3(1, 0, 0) - flatNormalWS * flatNormalWS.x);
            float3 bitangent = cross(tangent, flatNormalWS);
            return normalize(n.x * tangent + n.y * bitangent + n.z * flatNormalWS);
        }

        // Hooks for the shared helper passes: the same normal and smoothness go into the depth-normals texture,
        // so SSAO and screen space reflections see the floor as it is drawn.
        #define LIBRARY_DEPTH_NORMAL
        float3 LibraryDepthNormal(float2 uv, float3 positionWS, float3 normalWS) { return FloorNormal(positionWS, normalWS); }
        #define LIBRARY_SMOOTHNESS
        half LibrarySmoothness() { return _Smoothness; }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment

            // URP's keywords: shadows, extra lights (Forward+), reflection probes, SSR, SSAO, cookies, fog.
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SCREEN_SPACE_REFLECTION
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "../Common/Library-Lighting.hlsl"
            #include "../Common/Planar-Reflection.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                half   fogFactor  : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float3 normalWS = FloorNormal(input.positionWS, normalize(input.normalWS));
                half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, FloorUV(input.positionWS)).rgb * _BaseColor.rgb;

                // 1. The floor as URP's Lit would light it: lights, shadows, ambient, SSAO, probe or SSR reflection.
                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                SurfaceData surface = LibrarySurface(albedo, _Smoothness, half3(0, 0, 0));
                half4 color = UniversalFragmentPBR(inputData, surface);

                // 2. The planar reflection, added on top (black when no PlanarReflection renders for this camera).
                color.rgb += PlanarReflection(inputData, _Smoothness, _PlanarDistortion, _PlanarStretch, _PlanarStrength);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return half4(color.rgb, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex LibraryShadowVertex
            #pragma fragment LibraryShadowFragment
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ZWrite On
            ColorMask R
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex LibraryDepthOnlyVertex
            #pragma fragment LibraryDepthOnlyFragment
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex LibraryDepthNormalsVertex
            #pragma fragment LibraryDepthNormalsFragment
            #pragma multi_compile _ _WRITE_SMOOTHNESS
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
