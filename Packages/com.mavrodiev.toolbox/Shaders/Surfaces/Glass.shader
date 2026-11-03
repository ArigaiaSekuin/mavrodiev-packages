// Glass - clear, reeded or frosted.
// What it reads that the Lit shader does not:
//   the image behind it  -> what is behind the pane, moved by the normal map (bent) and, for frosted glass, blurred
//                           (_CameraOpaqueTexture: a copy of the frame made after the opaque objects are drawn)
//   the depth behind it  -> how far the things behind are: frosted glass blurs far things more than near ones
// The reflection on top is URP's own: the reflection probe, stronger at grazing angles (Fresnel).
// Needs Opaque Texture and Depth Texture on in the URP Asset (or on the camera).
// Glass drawn behind this glass is not in the Opaque Texture, so it does not show through.

Shader "Mavrodiev/Surfaces/Glass"
{
    Properties
    {
        _BaseColor ("Tint", Color) = (0.92, 0.97, 0.96, 1)
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Strength", Range(0, 2)) = 1
        _Refraction ("Refraction", Range(0, 0.3)) = 0.05
        _Frost ("Frost", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.95
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BumpMap_ST;
            half _BumpScale;
            half _Refraction;
            half _Frost;
            half _Smoothness;
        CBUFFER_END

        TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend Off      // the shader mixes the image behind with the reflection itself
            ZWrite On
            Cull Back

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
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #define _SURFACE_TYPE_TRANSPARENT 1
            #include "../Common/Library-Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                float4 tangentWS  : TEXCOORD3;
                half   fogFactor  : TEXCOORD4;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                VertexNormalInputs n = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = n.normalWS;
                output.tangentWS = float4(n.tangentWS, input.tangentOS.w * GetOddNegativeScale());
                output.uv = TRANSFORM_TEX(input.uv, _BumpMap);
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // The surface direction, with the normal map's bumps (reeds, ripples, a frosted grain).
                float3 flatNormal = normalize(input.normalWS);
                float3 bitangent = input.tangentWS.w * cross(flatNormal, input.tangentWS.xyz);
                half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv), _BumpScale);
                float3 normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, flatNormal)));

                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                float glassDepth = LinearEyeDepth(input.positionWS, UNITY_MATRIX_V);

                // 1. Refraction: where the bumps tilt the surface, look at the image behind a little to the side.
                float3 tilt = TransformWorldToViewDir(normalWS) - TransformWorldToViewDir(flatNormal);
                float2 bentUV = screenUV + tilt.xy * _Refraction;
                if (LinearEyeDepth(SampleSceneDepth(bentUV), _ZBufferParams) < glassDepth)
                    bentUV = screenUV;     // that pixel is in front of the glass: do not use it

                // 2. Frost: average 16 points of the image behind, spread over a small disc.
                //    The disc grows with the gap between the glass and what is behind it (up to 3 m).
                half3 behind = SampleSceneColor(bentUV);
                if (_Frost > 0.001)
                {
                    float gap = clamp(LinearEyeDepth(SampleSceneDepth(bentUV), _ZBufferParams) - glassDepth, 0.0, 3.0);
                    float radiusM = _Frost * (0.005 + 0.06 * gap);                        // blur radius in metres, at the glass
                    float radiusY = radiusM * UNITY_MATRIX_P[1][1] / (2.0 * glassDepth);  // ... as a share of the screen height
                    float2 radius = float2(radiusY * _ScreenParams.y / _ScreenParams.x, radiusY);
                    float spin = InterleavedGradientNoise(input.positionCS.xy, 0) * TWO_PI; // a different turn per pixel hides the pattern
                    half3 sum = 0; half weight = 0;
                    for (int i = 0; i < 16; i++)
                    {
                        // points on a "sunflower" spiral fill a disc evenly
                        float r = sqrt((i + 0.5) / 16.0);
                        float a = i * 2.39996 + spin;
                        float2 uv = bentUV + float2(cos(a), sin(a)) * r * radius;
                        half keep = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams) > glassDepth ? 1.0 : 0.0;
                        sum += SampleSceneColor(uv) * keep;
                        weight += keep;
                    }
                    if (weight > 0) behind = sum / weight;
                }

                // 3. The pane itself: a black, smooth surface - URP's PBR lighting gives only its reflections and highlights.
                //    What is behind is added as light, tinted, and weakened where the glass reflects more (Fresnel).
                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                half fresnel = LibraryFresnel(normalWS, inputData.viewDirectionWS, 0.04);
                half3 seenThrough = behind * _BaseColor.rgb * (1.0 - fresnel);
                half4 color = UniversalFragmentPBR(inputData, LibrarySurface(0, _Smoothness, seenThrough));

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return half4(color.rgb, 1);
            }
            ENDHLSL
        }

        // Glass lets light through, so there is no ShadowCaster pass: it casts no shadow.
        // The depth passes are used only when screen space reflections are set to reflect on transparent objects.

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
            #define LIBRARY_SMOOTHNESS
            half LibrarySmoothness() { return _Smoothness; }
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
