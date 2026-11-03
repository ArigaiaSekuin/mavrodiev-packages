// Ghost - a figure that glows at its edges and dissolves when the camera comes near.
// What it reads that the Lit shader does not:
//   the view direction  -> where the surface turns away from the camera (its silhouette) it glows (a Fresnel rim)
//   the camera distance -> closer than Fade Start it breaks up into dots, closer than Gone At it is invisible
// It ignores the lights: its colour is its own (like Unlit).
// Two passes: the first writes only depth, so the second draws only the nearest surface -
// otherwise the inner parts of the mesh would show through the transparent body.

Shader "Mavrodiev/Light-And-Space/Ghost"
{
    Properties
    {
        [HDR] _RimColor ("Edge Glow", Color) = (0.6, 1.4, 2.0, 1)
        _RimPower ("Edge Sharpness", Range(0.5, 8)) = 3
        _BodyColor ("Body Color (alpha = opacity)", Color) = (0.35, 0.55, 0.65, 0.08)
        _FadeStart ("Fade Start (m)", Float) = 5
        _FadeEnd ("Gone At (m)", Float) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _RimColor;
            half _RimPower;
            half4 _BodyColor;
            float _FadeStart;
            float _FadeEnd;
        CBUFFER_END

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
            float  visible    : TEXCOORD3;   // 1 = far enough, 0 = too close
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
            // the camera's distance to the object's pivot: the whole figure fades together
            float cameraDistance = distance(_WorldSpaceCameraPos, TransformObjectToWorld(float3(0, 0, 0)));
            output.visible = saturate((cameraDistance - _FadeEnd) / max(_FadeStart - _FadeEnd, 0.01));
            return output;
        }

        // Dissolving into dots: a fixed 4 x 4 pattern of thresholds (a Bayer matrix) repeated over the screen.
        // A pixel is kept only where "visible" is above its threshold, so fewer dots survive as the camera nears.
        void Dissolve(float4 positionCS, float visible)
        {
            static const float bayer[16] = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 };
            uint2 pixel = uint2(positionCS.xy / 3.0) % 4;   // each threshold covers 3 x 3 pixels, so the dots are visible
            clip(visible - (bayer[pixel.y * 4 + pixel.x] + 0.5) / 16.0);
        }
        ENDHLSL

        // Pass 1: depth only. Writes the nearest surface's depth, no colour.
        Pass
        {
            Name "GhostDepth"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment DepthFragment
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            half4 DepthFragment(Varyings input) : SV_Target
            {
                Dissolve(input.positionCS, input.visible);
                return 0;
            }
            ENDHLSL
        }

        // Pass 2: the colour. Premultiplied blending: the glow adds light, the body slightly hides what is behind.
        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }
            Blend One OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                Dissolve(input.positionCS, input.visible);
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                // Fresnel rim: 0 where the surface faces the camera, 1 where it turns away (the outline)
                half rim = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _RimPower);
                half3 color = _BodyColor.rgb * _BodyColor.a + _RimColor.rgb * rim;
                half alpha = saturate(_BodyColor.a + rim * 0.5);
                // fog fades the glow out too (it is added light, so fog mixes it towards black)
                color = MixFogColor(color, half3(0, 0, 0), InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor));
                return half4(color, alpha);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
