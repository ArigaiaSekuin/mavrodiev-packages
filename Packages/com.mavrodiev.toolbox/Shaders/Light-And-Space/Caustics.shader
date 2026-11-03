// Caustics - the moving net of light that water throws on a pool's floor and walls.
// It is the material of the surface under the water (the pool tiles), lit like URP Lit, plus the net of light.
// What it reads that the Lit shader does not:
//   time                      -> the net moves (two layers of cells drifting at different speeds)
//   its height in the world   -> the net appears only below Water Height, and fades with depth
//   the lights and shadows    -> the net is a share of each light that reaches the surface: none in shadow, none without a light
// The net is placed where each light's ray crossed the water surface, so it slides when the light moves.
// It is computed on the surface in the world, so it holds up from every side and in VR.
// It does not need a Water material above it; with one, the pool floor seen through the water shows the net too.
// DRAFT 2026-10-27 for the toolbox (Shaders/Light-And-Space). Check in the editor: compiles with Forward+ (the light loop), the spot lights add their net.

Shader "Mavrodiev/Light-And-Space/Caustics"
{
    Properties
    {
        [Header(Base material  (read like URP Lit))]
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _MetallicGlossMap ("Metallic Map (R metallic, A smoothness)", 2D) = "white" {}
        _Metallic ("Metallic (x map R)", Range(0, 1)) = 0
        _Smoothness ("Smoothness (x map A)", Range(0, 1)) = 0.5
        [Normal][NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Strength", Float) = 1

        [Header(Caustics)]
        _WaterHeight ("Water Height (world Y, m)", Float) = 0
        [HDR] _CausticColor ("Caustic Color", Color) = (0.85, 1, 1, 1)
        _CausticStrength ("Strength", Range(0, 4)) = 1.5
        _CausticSize ("Pattern Size (m)", Float) = 0.6
        _CausticSpeed ("Speed", Range(0, 3)) = 0.5
        _CausticSharpness ("Line Sharpness", Range(1, 30)) = 10
        _ColorSplit ("Colour Split", Range(0, 0.1)) = 0.015
        _DepthFade ("Fade with Depth (m)", Float) = 3
        _SurfaceFade ("Fade near the Surface (m)", Float) = 0.05
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _Metallic;
            half _Smoothness;
            half _BumpScale;
            float _WaterHeight;
            half4 _CausticColor;
            half _CausticStrength;
            float _CausticSize;
            half _CausticSpeed;
            half _CausticSharpness;
            half _ColorSplit;
            float _DepthFade;
            float _SurfaceFade;
        CBUFFER_END

        TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
        TEXTURE2D(_MetallicGlossMap); SAMPLER(sampler_MetallicGlossMap);
        TEXTURE2D(_BumpMap);          SAMPLER(sampler_BumpMap);

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
                float4 tangentWS  : TEXCOORD3;   // xyz: tangent, w: sign
                half   fogFactor  : TEXCOORD4;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                VertexPositionInputs p = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs n = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.positionWS = p.positionWS;
                output.positionCS = p.positionCS;
                output.normalWS = n.normalWS;
                output.tangentWS = float4(n.tangentWS, input.tangentOS.w * GetOddNegativeScale());
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(p.positionCS.z);
                return output;
            }

            // ---------- the net of light ----------
            float2 Hash2(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            // Cells around moving points: 0 on the border between two cells, larger inside a cell.
            // The bright lines of a caustic net run along these borders.
            float CellBorder(float2 p, float t)
            {
                float2 cell = floor(p);
                float2 f = frac(p);
                float d1 = 8.0, d2 = 8.0;
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 point_ = 0.5 + 0.4 * sin(t + 6.2832 * Hash2(cell + g));   // each point circles slowly
                    float d = length(g + point_ - f);
                    if (d < d1) { d2 = d1; d1 = d; }
                    else if (d < d2) { d2 = d; }
                }
                return d2 - d1;
            }

            // two layers of the net, at different sizes and speeds; brightest where their lines cross
            half Net(float2 p)
            {
                float t = _Time.y * _CausticSpeed;
                half a = exp(-CellBorder(p, t) * _CausticSharpness);
                half b = exp(-CellBorder(p * 1.37 + float2(3.1, 1.7), t * 1.23 + 2.0) * _CausticSharpness);
                return 0.5 * (a + b) + a * b;
            }

            half3 NetColor(float2 p)
            {
                half3 net = Net(p).xxx;
                // red, green and blue bend a little differently in water: three slightly shifted nets
                if (_ColorSplit > 0) net = half3(Net(p + float2(_ColorSplit, 0)), net.g, Net(p - float2(_ColorSplit, 0)));
                return net;
            }

            // the share of one light that the water focuses into the net, on this pixel
            half3 CausticFromLight(Light light, float3 positionWS, float3 normalWS, float depth)
            {
                half reach = saturate(dot(normalWS, light.direction)) * light.distanceAttenuation * light.shadowAttenuation;
                if (reach <= 0) return 0;
                // follow the light's ray back up to the water surface: the net is placed where it crossed it
                float up = max(light.direction.y, 0.05);
                float3 crossing = positionWS + light.direction * (depth / up);
                return light.color * reach * NetColor(crossing.xz / _CausticSize);
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // 1 · the base material, as URP Lit reads it
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                half4 metalGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
                half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv), _BumpScale);
                float3 bitangent = input.tangentWS.w * cross(input.normalWS, input.tangentWS.xyz);
                float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS));

                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                SurfaceData surface = LibrarySurface(albedo.rgb, metalGloss.a * _Smoothness, half3(0, 0, 0));
                surface.metallic = metalGloss.r * _Metallic;
                half4 color = UniversalFragmentPBR(inputData, surface);

                // 2 · the net of light, below the water only
                float depth = _WaterHeight - input.positionWS.y;
                if (depth > 0)
                {
                    half fade = saturate(depth / max(_SurfaceFade, 1e-3)) * exp(-depth / max(_DepthFade, 1e-3));
                    half3 caustic = CausticFromLight(GetMainLight(inputData.shadowCoord), inputData.positionWS, inputData.normalWS, depth);
                #if defined(_ADDITIONAL_LIGHTS)
                    uint lightCount = GetAdditionalLightsCount();
                    LIGHT_LOOP_BEGIN(lightCount)
                        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, half4(1, 1, 1, 1));
                        caustic += CausticFromLight(light, inputData.positionWS, inputData.normalWS, depth);
                    LIGHT_LOOP_END
                #endif
                    color.rgb += caustic * albedo.rgb * _CausticColor.rgb * _CausticStrength * fade;
                }

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
