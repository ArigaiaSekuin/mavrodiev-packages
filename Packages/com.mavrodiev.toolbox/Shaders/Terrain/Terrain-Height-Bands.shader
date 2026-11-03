// Terrain Height Bands - a terrain coloured by its height and its slope, with no Terrain Layers.
// What it reads that URP's Terrain Lit does not:
//   the height of each pixel above the object's origin (the terrain's corner), in metres -> low, mid or high colour
//   the direction the surface faces                                                      -> steep slopes take the Steep colour
// So the colours follow the shape: sculpt or generate the hills, and the bands move with them. Nothing is painted.
// Use: Terrain › Terrain Settings › Material = a material with this shader, and Draw Instanced OFF
// (with Draw Instanced on, the terrain builds its mesh from the heightmap in the shader, which this shader does not do).
// From Petar's Dancerex shaders (HeightBandTerrain, HeightBasedTerrain), rewritten on the toolbox's Library passes, 2026-11-03.

Shader "Mavrodiev/Terrain/Height-Bands"
{
    Properties
    {
        _LowColor ("Low Color", Color) = (0.30, 0.36, 0.22, 1)
        _MidColor ("Mid Color", Color) = (0.55, 0.50, 0.38, 1)
        _HighColor ("High Color", Color) = (0.92, 0.92, 0.90, 1)
        _LowHeight ("Low to Mid (m)", Float) = 8
        _HighHeight ("Mid to High (m)", Float) = 20
        _BlendRange ("Blend (m)", Range(0, 10)) = 2
        [Space(8)]
        _SteepColor ("Steep Color", Color) = (0.35, 0.33, 0.32, 1)
        _SteepAngle ("Steep from (degrees)", Range(0, 90)) = 40
        _SteepBlend ("Steep Blend (degrees)", Range(0, 30)) = 6
        [Space(8)]
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _LowColor;
            half4 _MidColor;
            half4 _HighColor;
            float _LowHeight;
            float _HighHeight;
            float _BlendRange;
            half4 _SteepColor;
            half _SteepAngle;
            half _SteepBlend;
            half _Smoothness;
        CBUFFER_END

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
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing

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
                InputData inputData = LibraryInputData(input.positionWS, input.normalWS, input.positionCS, input.fogFactor);
                // the height above the object's origin: for a terrain, above its corner, so moving the terrain changes nothing
                float height = input.positionWS.y - UNITY_MATRIX_M._m13;
                float lowMid  = smoothstep(_LowHeight - _BlendRange, _LowHeight + _BlendRange, height);
                float midHigh = smoothstep(_HighHeight - _BlendRange, _HighHeight + _BlendRange, height);
                half3 albedo = lerp(_LowColor.rgb, _MidColor.rgb, lowMid);
                albedo = lerp(albedo, _HighColor.rgb, midHigh);

                // the slope: 0 degrees = flat ground, 90 = a vertical wall
                float slope = degrees(acos(saturate(normalize(input.normalWS).y)));
                albedo = lerp(albedo, _SteepColor.rgb, smoothstep(_SteepAngle - _SteepBlend, _SteepAngle + _SteepBlend, slope));

                SurfaceData surface = LibrarySurface(albedo, _Smoothness, half3(0, 0, 0));
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
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
