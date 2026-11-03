// Water - a pool, a puddle or a flooded floor.
// What it reads that the Lit shader does not:
//   time                  -> two ripple normal maps slide over each other, so the surface moves
//   the image behind it   -> what is under the water, bent by the ripples (_CameraOpaqueTexture)
//   the depth behind it   -> how far the floor is below the surface, so deep water is darker (_CameraDepthTexture)
// Meant for horizontal surfaces: the ripples are placed in world space, in metres, on X and Z.
// Needs Opaque Texture and Depth Texture on in the URP Asset (or on the camera).

Shader "Mavrodiev/Surfaces/Water"
{
    Properties
    {
        _ShallowColor ("Shallow Tint", Color) = (0.8, 0.95, 0.95, 1)
        _DeepColor ("Deep Color", Color) = (0.02, 0.10, 0.12, 1)
        _DepthFade ("Depth Fade (m)", Float) = 1.5
        [Normal][NoScaleOffset] _NormalMap ("Ripple Normal Map", 2D) = "bump" {}
        _RippleStrength ("Ripple Strength", Range(0, 2)) = 0.6
        _RippleSize ("Ripple Size (m)", Float) = 1.5
        _FlowSpeed ("Flow Speed (m/s)", Float) = 0.05
        _Refraction ("Refraction", Range(0, 0.2)) = 0.04
        _Smoothness ("Smoothness", Range(0, 1)) = 0.95
    }

    SubShader
    {
        // Drawn after the opaque objects: it needs their finished image and depth.
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent-10" "IgnoreProjector" = "True" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // The material's settings (one block, the same in every pass, so the SRP Batcher can batch it).
        CBUFFER_START(UnityPerMaterial)
            half4 _ShallowColor;
            half4 _DeepColor;
            float _DepthFade;
            half _RippleStrength;
            float _RippleSize;
            float _FlowSpeed;
            half _Refraction;
            half _Smoothness;
        CBUFFER_END

        TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

        // The ripples: two copies of one normal map, at two sizes, sliding in two directions.
        // Their sum never repeats in an obvious way. The result is a world-space normal.
        float3 RippleNormal(float3 positionWS, float3 flatNormalWS)
        {
            float2 uv = positionWS.xz / _RippleSize;
            float slide = _Time.y * _FlowSpeed / _RippleSize;
            half3 a = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv + slide * float2(1.0, 0.35)), _RippleStrength);
            half3 b = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv * 0.63 + slide * float2(-0.45, -1.0)), _RippleStrength);
            half3 n = normalize(half3(a.xy + b.xy, a.z * b.z));
            // the normal maps' X and Y lie along the world's X and Z
            float3 tangent = normalize(float3(1, 0, 0) - flatNormalWS * flatNormalWS.x);
            float3 bitangent = cross(tangent, flatNormalWS);
            return normalize(n.x * tangent + n.y * bitangent + n.z * flatNormalWS);
        }

        // Hooks for the shared helper passes: the ripples and the smoothness also go into the
        // depth-normals texture, so screen space reflections (when on) can reflect in the water.
        #define LIBRARY_DEPTH_NORMAL
        float3 LibraryDepthNormal(float2 uv, float3 positionWS, float3 normalWS) { return RippleNormal(positionWS, normalWS); }
        #define LIBRARY_SMOOTHNESS
        half LibrarySmoothness() { return _Smoothness; }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            // The shader mixes the image behind with its own colour itself, so no blending is needed.
            Blend Off
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment

            // URP's keywords: shadows, extra lights (Forward+), reflection probes, SSR, fog.
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SCREEN_SPACE_REFLECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #define _SURFACE_TYPE_TRANSPARENT 1   // tells URP: no SSAO from the opaque objects under it
            #include "../Common/Library-Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

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

            // Vertex stage: nothing special - place the surface on the screen.
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

            // Fragment stage: the colour of one pixel of water.
            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float3 flatNormal = normalize(input.normalWS);
                float3 normalWS = RippleNormal(input.positionWS, flatNormal);
                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                float surfaceDepth = LinearEyeDepth(input.positionWS, UNITY_MATRIX_V); // this pixel's distance from the camera (eye depth)

                // 1. Refraction: look at the image behind a little to the side, by how much the ripple tilts the surface.
                float3 tilt = TransformWorldToViewDir(normalWS) - TransformWorldToViewDir(flatNormal);
                float2 bentUV = screenUV + tilt.xy * _Refraction;
                // If the bent pixel belongs to something in front of the water, do not bend there.
                if (LinearEyeDepth(SampleSceneDepth(bentUV), _ZBufferParams) < surfaceDepth)
                    bentUV = screenUV;
                half3 behind = SampleSceneColor(bentUV);

                // 2. Depth: find the point on the floor seen through this pixel, and how much water lies between.
                float floorRawDepth = SampleSceneDepth(bentUV);
                float3 floorWS = ComputeWorldSpacePosition(bentUV, floorRawDepth, UNITY_MATRIX_I_VP);
                float waterPath = distance(input.positionWS, floorWS);         // metres of water the light passes through
                half throughWater = exp(-3.0 * waterPath / max(_DepthFade, 0.01)); // 1 at the edge, almost 0 at Depth Fade metres

                // 3. The surface: reflections and highlights come from URP's PBR lighting (a black, very smooth surface).
                //    The deep colour is light scattered inside the water, so it is lit like a surface colour.
                //    What shows through from below is added as light, weakened where the surface reflects more (Fresnel).
                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                half fresnel = LibraryFresnel(normalWS, inputData.viewDirectionWS, 0.02);
                half3 deepColor = _DeepColor.rgb * (1.0 - throughWater);
                half3 seenBelow = behind * _ShallowColor.rgb * throughWater * (1.0 - fresnel);
                SurfaceData surface = LibrarySurface(deepColor, _Smoothness, seenBelow);
                half4 color = UniversalFragmentPBR(inputData, surface);

                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return half4(color.rgb, 1);
            }
            ENDHLSL
        }

        // Water casts no shadow: there is no ShadowCaster pass.
        // The two depth passes are used only when screen space reflections are set to reflect on transparent objects.

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
