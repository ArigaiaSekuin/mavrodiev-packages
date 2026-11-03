// Fake Beam - a beam of light faked with a cone mesh (The Flooded Arcade, station 5).
// It is an additive, transparent material: it adds its colour to whatever is behind it.
// What it reads:
//   the Gradient's alpha       -> bright at the lamp, fading toward the floor (V = 1 at the apex)
//   the view direction         -> where the cone's surface turns away from the camera (its outline) it fades,
//                                 so the cone has soft edges instead of a hard outline
// It reads no lights and no shadows: a wall in front of the lamp does not cut it.

Shader "Mavrodiev/Light-And-Space/Fake-Beam"
{
    Properties
    {
        [HDR] _Color ("Color", Color) = (1, 0.95, 0.85, 1)
        _BaseMap ("Gradient (alpha)", 2D) = "white" {}
        _EdgeSoftness ("Edge Softness", Range(0.5, 8)) = 2
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            Blend One One
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                float4 _BaseMap_ST;
                half _EdgeSoftness;
            CBUFFER_END

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

            struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; float2 uv : TEXCOORD0; };
            struct Varyings { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; float3 normalWS : TEXCOORD1; float3 viewWS : TEXCOORD2; float fog : TEXCOORD3; };

            Varyings vert (Attributes i)
            {
                Varyings o;
                VertexPositionInputs p = GetVertexPositionInputs(i.positionOS.xyz);
                o.positionCS = p.positionCS;
                o.uv = i.uv;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.viewWS = GetWorldSpaceViewDir(p.positionWS);
                o.fog = ComputeFogFactor(p.positionCS.z);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half a = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).a;
                // 1 where the surface faces the camera, 0 at the cone's outline
                half facing = abs(dot(normalize(i.normalWS), normalize(i.viewWS)));
                half3 c = _Color.rgb * a * pow(saturate(facing), _EdgeSoftness);
                // distance fog fades an added colour toward black (nothing added)
                c = MixFogColor(c, half3(0, 0, 0), i.fog);
                return half4(c, 1);
            }
            ENDHLSL
        }
    }
}
