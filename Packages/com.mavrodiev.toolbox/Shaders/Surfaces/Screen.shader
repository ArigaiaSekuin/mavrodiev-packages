// Screen - LED boards, CRT screens and lit signs: scrolling text, static noise, flicker.
// What it reads that the Lit shader does not:
//   time            -> the content scrolls (Scroll Speed), the static changes (Static Speed), the screen flickers
//   its own grid    -> the picture is cut into cells (Cells, columns x rows) along the UVs:
//                      LED = each cell one round dot; CRT = each row one bright line; Plain = no cells
// Everything is computed on the surface, in its UVs, so it holds up from every side and in VR.
// The content texture needs Wrap Mode Repeat (in U at least) for the scrolling.
// The glass on top is lit like Lit (reflections, highlights); the picture is emission: it lights nothing else.
// DRAFT 2026-10-27 for the toolbox (Shaders/Surfaces). Check in the editor: compiles; the LED dots fade to an even glow far away (no moire).

Shader "Mavrodiev/Surfaces/Screen"
{
    Properties
    {
        [Header(The glass)]
        _BaseColor ("Glass Color", Color) = (0.02, 0.02, 0.025, 1)
        _Smoothness ("Glass Smoothness", Range(0, 1)) = 0.85

        [Header(The picture)]
        [MainTexture] _Content ("Content (text or picture)", 2D) = "black" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (2, 2, 2, 1)
        _ScrollSpeed ("Scroll Speed (copies per second)", Float) = 0

        [Header(The cells)]
        [KeywordEnum(LED, CRT, Plain)] _Cells ("Cells", Float) = 0
        _Resolution ("Cells (columns, rows)", Vector) = (160, 20, 0, 0)
        _DotSize ("LED Dot Size", Range(0.2, 1)) = 0.8
        _OffLevel ("Unlit Cells Glow", Range(0, 0.2)) = 0.03

        [Header(Static and flicker)]
        _Static ("Static", Range(0, 1)) = 0
        _StaticSpeed ("Static Speed (changes per second)", Float) = 24
        _Flicker ("Flicker", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _Smoothness;
            float4 _Content_ST;
            half4 _EmissionColor;
            float _ScrollSpeed;
            float4 _Resolution;
            half _DotSize;
            half _OffLevel;
            half _Static;
            float _StaticSpeed;
            half _Flicker;
        CBUFFER_END

        TEXTURE2D(_Content); SAMPLER(sampler_Content);

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
            #pragma shader_feature_local _CELLS_LED _CELLS_CRT _CELLS_PLAIN

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
                return output;
            }

            // a dice roll: the same cell and moment always give the same number between 0 and 1
            float Dice(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.uv;
                float2 res = max(_Resolution.xy, 1.0);
                float2 gridUV = uv * res;                 // in cells
                float2 cell = floor(gridUV);
                float2 inCell = frac(gridUV);
                // how many cells one screen pixel covers: far away, the cells are smaller than a pixel
                float2 cellsPerPixel = fwidth(gridUV);
                half far = saturate(max(cellsPerPixel.x, cellsPerPixel.y) * 2.0 - 0.5); // 0 near, 1 when the cells blur together

                // 1 · where to read the picture: LED reads one value per cell (its centre), CRT one per row
            #if defined(_CELLS_LED)
                float2 readUV = (cell + 0.5) / res;
            #elif defined(_CELLS_CRT)
                float2 readUV = float2(uv.x, (cell.y + 0.5) / res.y);
            #else
                float2 readUV = uv;
            #endif
                float2 contentUV = readUV * _Content_ST.xy + _Content_ST.zw + float2(_Time.y * _ScrollSpeed, 0);
                // the derivatives of the smooth UV keep the mipmaps right where the read position jumps from cell to cell
                float2 smoothUV = uv * _Content_ST.xy;
                half3 picture = SAMPLE_TEXTURE2D_GRAD(_Content, sampler_Content, contentUV, ddx(smoothUV), ddy(smoothUV)).rgb;

                // 2 · static: every cell gets a new random grey many times a second
                float moment = floor(_Time.y * _StaticSpeed);
                half noise = Dice(cell + moment * float2(17.31, 5.17));
                picture = lerp(picture, noise.xxx, _Static);

                // 3 · the shape of a cell: a round dot (LED), a bright line across (CRT), or nothing (Plain)
            #if defined(_CELLS_LED)
                half d = length(inCell - 0.5) * 2.0;                       // 0 at the centre, 1 at the cell's edge
                half edge = max(cellsPerPixel.x, cellsPerPixel.y) * 2.0;     // a soft edge one pixel wide
                half dotMask = 1.0 - smoothstep(_DotSize - edge, _DotSize + edge, d);
                half coverage = 0.785 * _DotSize * _DotSize;                 // the dot's share of the cell (pi/4 x size^2)
                half shape = lerp(dotMask, coverage, far);
            #elif defined(_CELLS_CRT)
                half line_ = 0.55 + 0.45 * cos((inCell.y - 0.5) * 6.2832);
                half shape = lerp(line_, 0.775, far);
            #else
                half shape = 1.0;
            #endif

                // 4 · flicker: the whole screen dims for a moment, at random
                half flick = 1.0 - _Flicker * 0.4 * step(0.7, Dice(float2(floor(_Time.y * 30.0), 3.7)));

                half3 emission = _EmissionColor.rgb * shape * flick * (picture + _OffLevel);

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
