// Dust Back-Scatter - dust motes that show only where light passes through them (Particle-Effects, station 4).
// Ported from URP-Tests "Immersive-Spaces/Dust Back-Scatter" (Arches, Iteration-5) for the toolbox.
// What it reads that a lit particle does not:
//   every light's colour and shadow at the mote  -> a mote in shadow adds nothing; a mote in the beam adds the beam's light
//   the angle between the light and the camera   -> brightest when the light shines toward the camera (forward scattering,
//                                                   the Henyey-Greenstein phase function, as the volumetric fog does)
// A lit billboard cannot do this: it always faces the camera, so a back-lit speck shows its dark side.
// Additive and transparent: it only adds light, writes no depth and casts no shadow (so no depth or shadow pass).
// Works with or without a texture: Round Dot draws a soft round speck from the particle's UVs.
// Camera Fade: motes closer than Fade Near are invisible, so none flashes past the eye (VR).

Shader "Mavrodiev/Light-And-Space/Dust Back-Scatter"
{
    Properties
    {
        _BaseMap ("Mote (alpha)", 2D) = "white" {}
        [ToggleUI] _RoundDot ("Round Dot (no texture needed)", Float) = 1
        _Intensity ("Intensity", Float) = 1
        _Anisotropy ("Forward Scattering", Range(0, 0.95)) = 0.7
        _MaxBrightness ("Max Brightness", Float) = 12
        _FadeNear ("Camera Fade: gone at (m)", Float) = 0.3
        _FadeFar ("Camera Fade: full at (m)", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" "PreviewType" = "Plane" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Blend One One
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half _RoundDot;
                half _Intensity;
                half _Anisotropy;
                half _MaxBrightness;
                float _FadeNear;
                float _FadeFar;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                half4  color      : COLOR;      // the particle's colour (Start Color, Color over Lifetime)
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                half4  color      : COLOR;
                float3 positionWS : TEXCOORD1;
                half   fogFactor  : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                VertexPositionInputs p = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = p.positionCS;
                output.positionWS = p.positionWS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.color = input.color;
                output.fogFactor = ComputeFogFactor(p.positionCS.z);
                return output;
            }

            // Henyey-Greenstein phase: how much light is scattered toward the camera.
            // cosTheta = cosine of the angle between the light's travel direction and the direction to the camera.
            // g = 0 scatters evenly; g near 1 scatters almost all of it forward.
            half Phase(half cosTheta, half g)
            {
                half g2 = g * g;
                return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4), 1.5));
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 toCamera = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half3 sum = 0;

                // the main (directional) light, with its shadow and cookie
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS), input.positionWS, half4(1, 1, 1, 1));
                sum += mainLight.color * mainLight.shadowAttenuation * Phase(dot(-mainLight.direction, toCamera), _Anisotropy);

                // the other lights: spots and points (and, with Forward+, the extra directional lights)
                InputData inputData = (InputData)0;   // the light loop macro reads inputData by this name
                inputData.positionWS = input.positionWS;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

                #if USE_CLUSTER_LIGHT_LOOP
                [loop] for (uint dirIndex = 0; dirIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); dirIndex++)
                {
                    Light d = GetAdditionalLight(dirIndex, input.positionWS, half4(1, 1, 1, 1));
                    sum += d.color * d.distanceAttenuation * d.shadowAttenuation * Phase(dot(-d.direction, toCamera), _Anisotropy);
                }
                #endif

                uint lightCount = GetAdditionalLightsCount();
                LIGHT_LOOP_BEGIN(lightCount)
                    Light l = GetAdditionalLight(lightIndex, input.positionWS, half4(1, 1, 1, 1));
                    sum += l.color * l.distanceAttenuation * l.shadowAttenuation * Phase(dot(-l.direction, toCamera), _Anisotropy);
                LIGHT_LOOP_END

                // the speck's shape: the texture's alpha, times a soft round dot if Round Dot is on
                half texAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a;
                half r = length(input.uv * 2.0 - 1.0);              // 0 at the centre, 1 at the edge of the quad
                half roundDot = saturate(1.0 - r);
                roundDot *= roundDot;                               // soft falloff
                half mask = texAlpha * lerp(1.0, roundDot, _RoundDot) * input.color.a;

                // camera fade: invisible closer than _FadeNear, full from _FadeFar
                float distanceToCamera = distance(_WorldSpaceCameraPos, input.positionWS);
                mask *= saturate((distanceToCamera - _FadeNear) / max(_FadeFar - _FadeNear, 0.01));

                half3 color = min(sum * _Intensity, _MaxBrightness) * mask * input.color.rgb;
                // fog fades the added light toward black (like the Ghost and Fake-Beam shaders)
                color = MixFogColor(color, half3(0, 0, 0), InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor));
                return half4(color, 0);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
