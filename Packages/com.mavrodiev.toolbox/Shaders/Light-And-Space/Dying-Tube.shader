// Dying Tube - a fluorescent panel whose light stutters, dips and sometimes dies for a moment.
// What it reads that the Lit shader does not:
//   time -> the emission is switched by "dice rolls" made from the clock, so it flickers irregularly
//   its own position -> two tubes using the same material do not flicker together
// Only the panel's own surface flickers: emission is not a light. A Light under the panel stays steady
// unless a script changes its intensity.
// The flicker plays in Play mode, or in the Scene view with Always Refresh on.

Shader "Mavrodiev/Light-And-Space/Dying-Tube"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.85, 0.85, 0.85, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.4
        [HDR] _EmissionColor ("Emission Color", Color) = (4, 4.2, 4.4, 1)
        _Broken ("Broken", Range(0, 1)) = 0.6
        _FlickerSpeed ("Flicker Speed", Range(0.1, 3)) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _Smoothness;
            half4 _EmissionColor;
            half _Broken;
            half _FlickerSpeed;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

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
                nointerpolation float seed : TEXCOORD4;   // a number made from the object's position, the same on every pixel
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
                output.uv = input.uv;
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                float3 objectPosition = TransformObjectToWorld(float3(0, 0, 0));
                output.seed = frac(dot(objectPosition, float3(0.1031, 0.1130, 0.0973))) * 100.0;
                return output;
            }

            // A dice roll: the same input always gives the same number between 0 and 1.
            float Dice(float n) { n = frac(n * 0.1031); n *= n + 33.33; n *= n + n; return frac(n); }

            // How much the tube is on right now, from 0 (off) to 1 (fully on).
            half Flicker(float seed)
            {
                float t = _Time.y * _FlickerSpeed + Dice(seed) * 100.0;
                // every 0.8 s: a roll decides whether the tube is in trouble for that moment
                half trouble = Dice(floor(t / 0.8) + seed) < _Broken ? 1.0 : 0.0;
                // when in trouble: 25 rolls a second switch it on or off, each at its own brightness
                float tick = floor(t * 25.0);
                half stutter = Dice(tick + seed * 3.1) > 0.45 ? 0.3 + 0.7 * Dice(tick + 7.7) : 0.0;
                // every 3 s: a smaller roll lets it die completely for that moment
                half dead = Dice(floor(t / 3.0) + seed * 1.7) < _Broken * 0.3 ? 1.0 : 0.0;
                // a fast, slight hum that grows with the damage
                half hum = 1.0 - _Broken * 0.15 * Dice(floor(t * 60.0));
                return lerp(1.0, stutter, trouble) * (1.0 - dead) * hum;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half on = Flicker(input.seed);
                // an old tube is darker at its ends (along UV x)
                half ends = smoothstep(0.0, 0.15, input.uv.x) * smoothstep(1.0, 0.85, input.uv.x);
                half3 emission = _EmissionColor.rgb * on * lerp(1.0, 0.25 + 0.75 * ends, _Broken);

                InputData inputData = LibraryInputData(input.positionWS, normalize(input.normalWS), input.positionCS, input.fogFactor);
                half4 color = UniversalFragmentPBR(inputData, LibrarySurface(_BaseColor.rgb, _Smoothness, emission));
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
