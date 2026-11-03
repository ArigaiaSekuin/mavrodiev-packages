// Texel-Density - a debug view: how many texture pixels (texels) cover one metre of this surface.
// Used by Tools > Mavrodiev > Texel Density View, which makes one of these per material from the
// material's own Base Map (its size in pixels and its Tiling/Offset). It can also be assigned by hand.
// What it reads that the Lit shader does not:
//   the screen-space derivatives (ddx, ddy) of the texel position and of the world position:
//   their ratio is the texel density, in texels per metre, at every pixel.
// It shows:
//   a checker, one cell per "Texels Per Check" texels: equal cells = equal density, stretched cells = stretched UVs
//   a colour against the target density: green on target, blue at half or less, red at double or more
// Unlit: a little shading by the view angle, so the shapes still read.
// Install: Assets/_Staging/com.mavrodiev.toolbox/Shaders/Debug/Texel-Density.shader

Shader "Mavrodiev/Debug/Texel-Density"
{
    Properties
    {
        _TexSize ("Texture Size (pixels)", Vector) = (1024, 1024, 0, 0)
        _TexST ("Tiling (xy) and Offset (zw)", Vector) = (1, 1, 0, 0)
        [Toggle] _HasTexture ("Has a Texture", Float) = 1
        _Target ("Target Density (texels per metre)", Float) = 512
        _CheckTexels ("Texels Per Check", Float) = 64
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _TexSize;
            float4 _TexST;
            float _HasTexture;
            float _Target;
            float _CheckTexels;
        CBUFFER_END

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
            float3 positionWS : TEXCOORD0;
            float3 normalWS   : TEXCOORD1;
            float2 uv         : TEXCOORD2;
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
            return output;
        }
        ENDHLSL

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half shade = 0.6 + 0.4 * saturate(abs(dot(normalWS, viewDirWS)));

                // no texture: plain grey, so it reads as "nothing to measure"
                if (_HasTexture < 0.5)
                    return half4(0.45 * shade, 0.45 * shade, 0.45 * shade, 1);

                // where this pixel is on the texture, counted in texels (Tiling and Offset included, as Lit does)
                float2 texel = (input.uv * _TexST.xy + _TexST.zw) * _TexSize.xy;

                // density = sqrt(texel area / world area) covered between this pixel and its neighbours
                float2 tdx = ddx(texel), tdy = ddy(texel);
                float3 pdx = ddx(input.positionWS), pdy = ddy(input.positionWS);
                float texelArea = abs(tdx.x * tdy.y - tdx.y * tdy.x);
                float worldArea = length(cross(pdx, pdy));
                float density = sqrt(texelArea / max(worldArea, 1e-12));   // texels per metre

                // colour: how many doublings (stops) above or below the target
                float stops = clamp(log2(max(density, 1e-6) / max(_Target, 1e-6)), -1.0, 1.0);
                half3 low  = half3(0.20, 0.40, 1.00);   // half the target or less
                half3 on   = half3(0.25, 0.85, 0.30);   // on target
                half3 high = half3(1.00, 0.30, 0.20);   // double the target or more
                half3 color = stops < 0 ? lerp(on, low, -stops) : lerp(on, high, stops);

                // checker: one cell per _CheckTexels texels
                float2 cell = floor(texel / max(_CheckTexels, 1.0));
                half checker = frac((cell.x + cell.y) * 0.5) * 2.0;   // 0 or 1
                color *= lerp(0.6, 1.0, checker);

                return half4(color * shade, 1);
            }
            ENDHLSL
        }

        // Depth only: so the view works with the depth prepass and depth priming.
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment DepthFragment
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            half DepthFragment(Varyings input) : SV_Target
            {
                return input.positionCS.z;
            }
            ENDHLSL
        }

        // Depth and normals: so SSAO and screen space reflections still find the surfaces.
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            ZWrite On

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment DepthNormalsFragment
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            half4 DepthNormalsFragment(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);
            #if defined(_GBUFFER_NORMALS_OCT)
                float2 octNormalWS = PackNormalOctQuadEncode(normalWS);
                return half4(PackFloat2To888(saturate(octNormalWS * 0.5 + 0.5)), 0.0);
            #else
                return half4(normalWS, 0.0);
            #endif
            }
            ENDHLSL
        }
        // No ShadowCaster: a debug view, unlit; the objects drawn with it cast no shadows.
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
