// Triplanar - a texture placed by position, not by the mesh's UVs.
// What it reads that the Lit shader does not:
//   the position of each pixel (in the world, or in the object) -> the texture is projected from three sides, along X, Y and Z
//   the direction the surface faces                             -> how much of each of the three projections shows
// Texture Size sets how many metres one copy of the texture covers, the same on every object.
// Space = World: the texture stays in the world (move or scale the object: the texture does not follow).
// Space = Object: the texture follows the object when it moves or turns, and stretches when it is scaled.
// Lit like URP Lit (UniversalFragmentPBR); the normal map is blended with the whiteout method.
// DRAFT 2026-10-27 for the toolbox (Shaders/Surfaces). Check in the editor: compiles, lights like Lit, the bumps lit from the light's side on all six faces.

Shader "Mavrodiev/Surfaces/Triplanar"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _MetallicGlossMap ("Metallic Map (R metallic, A smoothness)", 2D) = "white" {}
        _Metallic ("Metallic (x map R)", Range(0, 1)) = 0
        _Smoothness ("Smoothness (x map A)", Range(0, 1)) = 0.5
        [Normal][NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Strength", Float) = 1
        _TextureSize ("Texture Size (m)", Float) = 2
        _BlendSharpness ("Blend Sharpness", Range(1, 16)) = 4
        [KeywordEnum(World, Object)] _Space ("Space", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _Metallic;
            half _Smoothness;
            half _BumpScale;
            float _TextureSize;
            half _BlendSharpness;
        CBUFFER_END

        TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
        TEXTURE2D(_MetallicGlossMap); SAMPLER(sampler_MetallicGlossMap);
        TEXTURE2D(_BumpMap);          SAMPLER(sampler_BumpMap);

        // smoothness written for screen space reflections (the map's alpha is not read here: an approximation)
        #define LIBRARY_SMOOTHNESS
        half LibrarySmoothness() { return _Smoothness; }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma shader_feature_local _SPACE_WORLD _SPACE_OBJECT

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SCREEN_SPACE_REFLECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "../Common/Library-Lighting.hlsl"

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
                float3 positionOS : TEXCOORD2;
                float3 normalOS   : TEXCOORD3;
                half   fogFactor  : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionOS = input.positionOS.xyz;
                output.normalOS = input.normalOS;
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            // The three projections. p: the position (world or object), n: the surface direction in the same space.
            // Returns the base colour, the metallic-smoothness map and the blended normal (in the same space as n).
            void SampleTriplanar(float3 p, float3 n, out half4 albedo, out half4 metalGloss, out float3 normal)
            {
                // how much each projection shows: the more a surface faces an axis, the more of that axis's projection
                float3 w = pow(abs(n), _BlendSharpness);
                w /= max(w.x + w.y + w.z, 1e-5);

                // the three sets of UVs, in metres / Texture Size; flipped on the back sides so the texture is not mirrored
                float3 s = step(0.0, n) * 2.0 - 1.0;
                float2 uvX = p.zy / _TextureSize; uvX.x *= s.x;
                float2 uvY = p.xz / _TextureSize; uvY.x *= s.y;
                float2 uvZ = p.xy / _TextureSize; uvZ.x *= -s.z;

                albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvX) * w.x
                       + SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvY) * w.y
                       + SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvZ) * w.z;
                metalGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uvX) * w.x
                           + SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uvY) * w.y
                           + SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uvZ) * w.z;

                // the normal map, once per projection, turned into the projection's own axes (whiteout blend)
                half3 tX = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvX), _BumpScale);
                half3 tY = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvY), _BumpScale);
                half3 tZ = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvZ), _BumpScale);
                tX.x *= s.x; tY.x *= s.y; tZ.x *= -s.z;
                tX = half3(tX.xy + n.zy, abs(tX.z) * n.x);
                tY = half3(tY.xy + n.xz, abs(tY.z) * n.y);
                tZ = half3(tZ.xy + n.xy, abs(tZ.z) * n.z);
                normal = normalize(tX.zyx * w.x + tY.xzy * w.y + tZ.xyz * w.z);
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 albedo, metalGloss;
                float3 normal;
            #if defined(_SPACE_OBJECT)
                SampleTriplanar(input.positionOS, normalize(input.normalOS), albedo, metalGloss, normal);
                float3 normalWS = TransformObjectToWorldNormal(normal);
            #else
                SampleTriplanar(input.positionWS, normalize(input.normalWS), albedo, metalGloss, normal);
                float3 normalWS = normal;
            #endif

                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                SurfaceData surface = LibrarySurface(albedo.rgb * _BaseColor.rgb, metalGloss.a * _Smoothness, half3(0, 0, 0));
                surface.metallic = metalGloss.r * _Metallic;
                half4 color = UniversalFragmentPBR(inputData, surface);
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

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex LibraryDepthOnlyVertex
            #pragma fragment LibraryDepthOnlyFragment
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }

        // writes the mesh's own normal (not the triplanar normal map) for SSAO and SSR
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            ZWrite On

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
