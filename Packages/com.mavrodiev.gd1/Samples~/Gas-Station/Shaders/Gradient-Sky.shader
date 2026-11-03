// Gas Station: HDRP's Gradient Sky for URP, as a skybox. Three colours (top, middle, bottom) blended by the view
// direction's height, sharpened by the diffusion, as in HDRP. The colours are linear HDR values (vectors, so Unity
// does no gamma conversion): HDRP's sky radiance times its exposure (EV 6.9: 1/143.3).
Shader "Gas-Station/Gradient Sky"
{
    Properties
    {
        _Top("Top (linear)", Vector) = (0.00105, 0.00488, 0.00768, 0)
        _Middle("Middle (linear)", Vector) = (0.00349, 0.01535, 0.02512, 0)
        _Bottom("Bottom (linear)", Vector) = (0.0014, 0.00558, 0.00768, 0)
        _Diffusion("Gradient Diffusion", Float) = 1.5
        _Intensity("Intensity", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" "RenderPipeline" = "UniversalPipeline" }
        Cull Off ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _Top, _Middle, _Bottom;
            float _Diffusion, _Intensity;

            struct Attributes { float4 positionOS : POSITION; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct Varyings { float4 positionCS : SV_POSITION; float3 dirWS : TEXCOORD0; UNITY_VERTEX_OUTPUT_STEREO };

            Varyings vert(Attributes v)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.dirWS = v.positionOS.xyz;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float y = normalize(i.dirWS).y * _Diffusion;
                float3 c = lerp(_Middle.rgb, _Top.rgb, saturate(y));
                c = lerp(c, _Bottom.rgb, saturate(-y));
                return half4(c * _Intensity, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
