// Damp-Base — damp rising from the ground: darker and a little smoother below a height measured in the world.
// Part of the GD1 graphics playground (Assets/Playground/Textures/Wear-And-Weather). Built on URP 17.6's Lit passes:
// SurfaceBase.hlsl reads the base material, SurfaceForwardPass.hlsl lights it, and MixLayer() below is the lesson.
Shader "Mavrodiev/Weathering/Damp-Base"
{
    Properties
    {
        [Header(Base material  (read like URP Lit))]
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        [NoScaleOffset] _MetallicGlossMap("Metallic Map (R metallic, A smoothness)", 2D) = "white" {}
        _Metallic("Metallic (x map R)", Range(0, 1)) = 0
        _Smoothness("Smoothness (x map A)", Range(0, 1)) = 0.5
        [Normal][NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Strength", Float) = 1
        [NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
        [HideInInspector] _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5

        [Header(Damp  (rising from the ground))]
        _GroundHeight("Ground Height (world Y, m)", Float) = 0
        _DampHeight("Damp Height (m)", Range(0, 3)) = 0.8
        _DampEdge("Edge Raggedness (m)", Range(0, 0.6)) = 0.2
        _DampDarkening("Damp Darkening", Range(0, 1)) = 0.45
        _DampSmoothness("Damp Smoothness", Range(0, 1)) = 0.35
        _TideLine("Tide Line (salt at the edge)", Range(0, 1)) = 0.5
        _DampNoiseSize("Noise Size (m)", Float) = 1.2
        [NoScaleOffset] _NoiseMap("Noise (tileable)", 2D) = "grey" {}
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" }
        LOD 300

        HLSLINCLUDE
        #define _NORMALMAP 1
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

        // every material property, in one block (needed by the SRP Batcher)
        CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half4 _BaseColor;
        half _Cutoff;
        half _Metallic;
        half _Smoothness;
        half _BumpScale;
        half _OcclusionStrength;
        float _GroundHeight;
        half _DampHeight;
        half _DampEdge;
        half _DampDarkening;
        half _DampSmoothness;
        half _TideLine;
        float _DampNoiseSize;
        CBUFFER_END

        #include "SurfaceBase.hlsl"

        void MixLayer(MixInput m, inout SurfaceData s)
        {
            // the mask: the height above the ground, in the world (not on the object)
            float height = m.positionWS.y - _GroundHeight;
            float along = m.positionWS.x + m.positionWS.z;                // along the wall
            half noise = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, float2(along, height * 0.4) / _DampNoiseSize).r;
            float edge = _DampHeight + (noise - 0.5) * 2.0 * _DampEdge;
            half damp = 1.0 - smoothstep(edge - 0.1, edge, height);
            half tide = smoothstep(edge - 0.12, edge - 0.03, height) * (1.0 - smoothstep(edge - 0.01, edge + 0.04, height)) * _TideLine;

            // the damp layer: darker and a little smoother; a pale line of salt where it stops
            s.albedo *= 1.0 - _DampDarkening * damp;
            s.smoothness = lerp(s.smoothness, max(s.smoothness, _DampSmoothness), damp);
            s.albedo = lerp(s.albedo, half3(0.62, 0.6, 0.55), tide * 0.7);
        }

        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex SurfacePassVertex
            #pragma fragment SurfacePassFragment

            // the same Universal Pipeline keywords as URP Lit (lights, shadows, probes, SSR, SSAO, decals, Forward+)
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SCREEN_SPACE_REFLECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _SCREEN_SPACE_IRRADIANCE
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ LIGHTMAP_BICUBIC_SAMPLING
            #pragma multi_compile_fragment _ REFLECTION_PROBE_ROTATION
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ProbeVolumeVariants.hlsl"
            #pragma multi_compile_instancing

            #include "SurfaceForwardPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #pragma multi_compile_instancing
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ZWrite On
            ColorMask R
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // the normals (and smoothness) that SSAO, decals and screen-space reflections read
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex SurfaceDepthNormalsVertex
            #pragma fragment SurfaceDepthNormalsFragment
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            #pragma multi_compile _ _WRITE_SMOOTHNESS
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_instancing
            #include "SurfaceDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
