// Wet-Puddles — a surface that gets wet (darker and smoother) and holds puddles where a height mask is below the water level.
// Part of the GD1 graphics playground (Assets/Playground/Textures/Wear-And-Weather). Built on URP 17.6's Lit passes:
// SurfaceBase.hlsl reads the base material, SurfaceForwardPass.hlsl lights it, and MixLayer() below is the lesson.
Shader "Mavrodiev/Weathering/Wet-Puddles"
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

        [Header(Wetness  (the whole surface))]
        _Wetness("Wetness", Range(0, 1)) = 0
        _WetDarkening("Wet Darkening", Range(0, 1)) = 0.5
        _WetSmoothness("Wet Smoothness", Range(0, 1)) = 0.85

        [Header(Puddles  (placed by the mask))]
        _PuddleMask("Puddle Mask (R = height, dark = low)", 2D) = "white" {}
        _WaterLevel("Water Level", Range(0, 1)) = 0.4
        _PuddleEdge("Puddle Edge Softness", Range(0.005, 0.2)) = 0.03
        _PuddleRim("Wet Rim Around Puddles", Range(0, 0.3)) = 0.08
        _PuddleColor("Puddle Tint", Color) = (0.6, 0.6, 0.6, 1)
        _PuddleSmoothness("Puddle Smoothness", Range(0, 1)) = 0.97
        _RippleStrength("Rain Ripples", Range(0, 1)) = 0.25
        _RippleSize("Ripple Size (m)", Float) = 0.4
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
        float4 _PuddleMask_ST;
        half _Wetness;
        half _WetDarkening;
        half _WetSmoothness;
        half _WaterLevel;
        half _PuddleEdge;
        half _PuddleRim;
        half4 _PuddleColor;
        half _PuddleSmoothness;
        half _RippleStrength;
        float _RippleSize;
        CBUFFER_END
        TEXTURE2D(_PuddleMask); SAMPLER(sampler_PuddleMask);

        #include "SurfaceBase.hlsl"

        // one layer of rain drops: a ring grows from a random point in each cell and fades
        float2 RippleSlope(float2 p, float t)
        {
            float2 cell = floor(p);
            float2 d = frac(p) - (0.5 + (float2(SurfHash(cell + 17.0), SurfHash(cell + 31.0)) - 0.5) * 0.5);
            float r = length(d);
            float life = frac(t * 0.6 + SurfHash(cell));      // 0 = the drop lands, 1 = the ring is gone
            float x = (r - life * 0.42) * 45.0;                 // distance from the ring
            float wave = cos(x) * exp(-x * x * 0.12) * (1.0 - life);
            return d / max(r, 1e-4) * wave;
        }

        void MixLayer(MixInput m, inout SurfaceData s)
        {
            // the mask: a grey height map; the water fills everything below the level
            half h = SAMPLE_TEXTURE2D(_PuddleMask, sampler_PuddleMask, TRANSFORM_TEX(m.uv0, _PuddleMask)).r;
            half puddle = saturate((_WaterLevel - h) / _PuddleEdge) * step(0.001, _WaterLevel);
            half rim = saturate((_WaterLevel + _PuddleRim - h) / max(_PuddleRim, 1e-3)) * step(0.001, _WaterLevel);

            // 1 · wet: darker and smoother (everywhere with Wetness, and on the rim of each puddle)
            half wet = max(_Wetness, rim);
            s.albedo *= 1.0 - _WetDarkening * wet;
            s.smoothness = lerp(s.smoothness, max(s.smoothness, _WetSmoothness), wet);
            s.normalTS = SurfFlatten(s.normalTS, wet * _WetSmoothness);   // the film of water fills the small bumps

            // 2 · in the puddle: water covers the surface — tinted, very smooth, flat (plus rain ripples)
            float2 p = m.uv0 / _RippleSize;
            float2 slope = RippleSlope(p, _Time.y) + RippleSlope(p * 1.31 + 0.37, _Time.y + 0.5);
            half3 waterNormal = normalize(half3(-slope * 0.35 * _RippleStrength, 1.0));
            s.albedo = lerp(s.albedo, s.albedo * _PuddleColor.rgb, puddle);
            s.smoothness = lerp(s.smoothness, _PuddleSmoothness, puddle);
            s.metallic = lerp(s.metallic, 0.0, puddle);
            s.occlusion = lerp(s.occlusion, 1.0, puddle);
            s.normalTS = normalize(lerp(s.normalTS, waterNormal, puddle));
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
