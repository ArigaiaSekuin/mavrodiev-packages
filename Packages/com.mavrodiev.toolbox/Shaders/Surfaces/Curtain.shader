// Curtain - thin cloth that glows when a light is behind it, and waves gently.
// What it reads that the Lit shader does not:
//   the light from behind  -> light arriving on the far side of the cloth comes through it (transmission)
//   time, in the vertex stage -> every vertex is pushed back and forth, so the cloth waves
// The vertex stage can only move vertices that exist: use a mesh with many vertices (a subdivided plane).
// The movement is only in the drawing: the mesh data, and so a Mesh Collider, stay flat.

Shader "Mavrodiev/Surfaces/Curtain"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (0.45, 0.06, 0.05, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.2
        _Transmission ("Light Through", Range(0, 4)) = 1.5
        _WaveHeight ("Wave Height (m)", Range(0, 0.3)) = 0.05
        _WaveLength ("Wave Length (m)", Float) = 0.7
        _WaveSpeed ("Wave Speed", Float) = 0.6
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Smoothness;
            half _Transmission;
            float _WaveHeight;
            float _WaveLength;
            float _WaveSpeed;
        CBUFFER_END

        TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

        // The wave, in the vertex stage. The cloth hangs in the mesh's X-Y plane, top at UV y = 1.
        // It is pinned at the top and swings more towards the bottom. Two waves of different length
        // run across it; the normal is turned to follow the new shape, so the lighting folds too.
        #define LIBRARY_DISPLACE
        void LibraryDisplace(inout float3 positionOS, inout float3 normalOS, float2 uv)
        {
            float t = _Time.y * _WaveSpeed * TWO_PI;
            float k = TWO_PI / max(_WaveLength, 0.01);
            float x = positionOS.x, y = positionOS.y;
            float pin = pow(saturate(1.0 - uv.y), 0.8);                 // 0 at the top, 1 at the bottom
            float a1 = k * x + t;                 float s1 = sin(a1);
            float a2 = 1.7 * k * (0.6 * x + 0.3 * y) - 1.3 * t + 2.0; float s2 = sin(a2);
            float push = _WaveHeight * pin * (0.7 * s1 + 0.3 * s2 + 0.4 * sin(0.37 * t));
            // the slope of the push along X and Y (its derivative) tilts the normal
            float dx = _WaveHeight * pin * (0.7 * k * cos(a1) + 0.3 * 1.7 * k * 0.6 * cos(a2));
            float dy = _WaveHeight * pin * (0.3 * 1.7 * k * 0.3 * cos(a2));
            positionOS += normalOS * push;
            normalOS = normalize(normalOS - dx * float3(1, 0, 0) - dy * float3(0, 1, 0));
        }
        #define LIBRARY_TWO_SIDED
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Cull Off          // a curtain is seen from both sides

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
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
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                half   fogFactor  : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // Vertex stage: move the vertex (the wave), then place it on the screen.
            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                LibraryDisplace(input.positionOS.xyz, input.normalOS, input.uv);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            // The light that comes through the cloth from one light: how much of it falls on the far side.
            // The shadow is looked up a few centimetres towards the light, so the cloth does not shadow itself,
            // but anything between the light and the cloth (a figure) still casts its shadow on it.
            half3 Through(Light light, float3 normalWS, float3 viewDirWS)
            {
                half farSide = saturate(dot(-normalWS, light.direction));                       // the light hits the back
                half towardEye = pow(saturate(dot(viewDirWS, -light.direction)), 4.0);           // looking into the light
                return light.color * light.distanceAttenuation * light.shadowAttenuation * (farSide * 0.6 + towardEye * 0.4);
            }

            // Fragment stage: the cloth's colour, lit from the front by URP's PBR lighting, plus the light through it.
            half4 Fragment(Varyings input, FRONT_FACE_TYPE face : FRONT_FACE_SEMANTIC) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                // the back of the cloth faces the other way
                float3 normalWS = normalize(input.normalWS) * IS_FRONT_VFACE(face, 1.0, -1.0);
                half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb * _BaseColor.rgb;

                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                half4 color = UniversalFragmentPBR(inputData, LibrarySurface(albedo, _Smoothness, 0));

                // transmission: the main light, then every extra light (Forward+ walks them with LIGHT_LOOP)
                half3 through = 0;
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS + _MainLightPosition.xyz * 0.1));
                through += Through(mainLight, normalWS, inputData.viewDirectionWS);
            #if defined(_ADDITIONAL_LIGHTS)
                uint lightCount = GetAdditionalLightsCount();
                #if USE_CLUSTER_LIGHT_LOOP
                for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    light = GetAdditionalLight(lightIndex, input.positionWS + light.direction * 0.1, half4(1, 1, 1, 1));
                    through += Through(light, normalWS, inputData.viewDirectionWS);
                }
                #endif
                LIGHT_LOOP_BEGIN(lightCount)
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    light = GetAdditionalLight(lightIndex, input.positionWS + light.direction * 0.1, half4(1, 1, 1, 1));
                    through += Through(light, normalWS, inputData.viewDirectionWS);
                LIGHT_LOOP_END
            #endif
                color.rgb += through * albedo * _Transmission;

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
            Cull Off

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
            Cull Off

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
            Cull Off

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
