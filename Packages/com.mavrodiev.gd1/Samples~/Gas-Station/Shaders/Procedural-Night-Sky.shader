// Gas Station: a procedural night sky for URP, as a skybox. The Gradient Sky's three colours (top, middle, bottom), plus
// drifting clouds (fractal noise projected on a plane above the camera, lit from below by the town's glow), stars that the
// clouds cover, a moon with a soft glow, and a warm glow along the horizon. Colours are linear HDR values (vectors, so Unity
// does no gamma conversion), at the scale of the Gradient Sky: the night sky is about a hundred times darker than the lights.
Shader "Gas-Station/Procedural Night Sky"
{
    Properties
    {
        [Header(Gradient)]
        _Top("Top (linear)", Vector) = (0.00105, 0.00488, 0.00768, 0)
        _Middle("Middle (linear)", Vector) = (0.00349, 0.01535, 0.02512, 0)
        _Bottom("Bottom (linear)", Vector) = (0.0014, 0.00558, 0.00768, 0)
        _Diffusion("Gradient Diffusion", Float) = 1.5
        [Header(Horizon glow)]
        _HorizonGlow("Horizon Glow (linear)", Vector) = (0.012, 0.007, 0.003, 0)
        _HorizonFalloff("Horizon Glow Falloff", Range(1, 40)) = 9
        [Header(Clouds)]
        _CloudColor("Cloud Colour (linear)", Vector) = (0.006, 0.011, 0.014, 0)
        _CloudGlowFromBelow("Lit by the Horizon Glow", Range(0, 4)) = 1.5
        _CloudCover("Cover", Range(0, 1)) = 0.5
        _CloudSoftness("Softness", Range(0.01, 1)) = 0.35
        _CloudOpacity("Opacity", Range(0, 1)) = 0.9
        _CloudScale("Scale", Float) = 0.6
        _CloudSpeed("Drift (x, z per second)", Vector) = (0.004, 0.0015, 0, 0)
        [Header(Stars)]
        _StarDensity("Density", Float) = 220
        _StarAmount("Amount", Range(0, 1)) = 0.12
        _StarIntensity("Intensity (linear)", Float) = 0.12
        _StarTwinkle("Twinkle Speed", Float) = 1.5
        [Header(Moon)]
        _MoonDirection("Direction", Vector) = (0.325, 0.309, 0.894, 0)
        _MoonSize("Size (degrees)", Range(0.1, 10)) = 1.6
        _MoonColor("Colour (linear)", Vector) = (0.85, 0.9, 1, 0)
        _MoonIntensity("Disc Intensity", Float) = 0.6
        _MoonGlow("Glow Intensity", Float) = 0.015
        _MoonGlowFalloff("Glow Falloff", Range(1, 2000)) = 300
        [Header(All)]
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

            float4 _Top, _Middle, _Bottom, _HorizonGlow, _CloudColor, _CloudSpeed, _MoonDirection, _MoonColor;
            float _Diffusion, _HorizonFalloff, _CloudGlowFromBelow, _CloudCover, _CloudSoftness, _CloudOpacity, _CloudScale;
            float _StarDensity, _StarAmount, _StarIntensity, _StarTwinkle;
            float _MoonSize, _MoonIntensity, _MoonGlow, _MoonGlowFalloff, _Intensity;

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

            float Hash(float2 p)
            {
                float3 p3 = frac(p.xyx * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }

            float Noise(float2 p)
            {
                float2 i = floor(p), f = frac(p);
                float2 u = f * f * (3 - 2 * f);
                return lerp(lerp(Hash(i), Hash(i + float2(1, 0)), u.x), lerp(Hash(i + float2(0, 1)), Hash(i + 1), u.x), u.y);
            }

            // Fractal noise: five octaves, each twice as fine and half as strong.
            float Fbm(float2 p)
            {
                float v = 0, a = 0.5;
                [unroll] for (int k = 0; k < 5; k++) { v += a * Noise(p); p = p * 2.03 + 17.1; a *= 0.5; }
                return v;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 d = normalize(i.dirWS);
                float up = saturate(d.y);

                // the gradient, as in the Gradient Sky
                float y = d.y * _Diffusion;
                float3 c = lerp(_Middle.rgb, _Top.rgb, saturate(y));
                c = lerp(c, _Bottom.rgb, saturate(-y));

                // the town's glow along the horizon
                float3 horizon = _HorizonGlow.rgb * exp(-abs(d.y) * _HorizonFalloff);
                c += horizon;

                // clouds on a plane above the camera, thinning toward the horizon
                float2 cp = d.xz / max(d.y, 0.03) * _CloudScale + _Time.y * _CloudSpeed.xy;
                float cover = smoothstep(1 - _CloudCover, 1 - _CloudCover + _CloudSoftness, Fbm(cp));
                cover *= smoothstep(0.0, 0.12, d.y) * _CloudOpacity;

                // stars: one per cell at most, on a latitude-longitude grid
                float2 sp = float2(atan2(d.x, d.z), asin(clamp(d.y, -1, 1))) * _StarDensity / PI;
                float2 cell = floor(sp);
                float h = Hash(cell);
                float2 offset = float2(Hash(cell + 7.31), Hash(cell + 3.17)) - 0.5;
                float star = step(1 - _StarAmount, h) * smoothstep(0.12, 0.0, length(frac(sp) - 0.5 - offset * 0.6));
                star *= (0.7 + 0.3 * sin(_Time.y * _StarTwinkle * (1 + h * 3) + h * 40)) * smoothstep(0.02, 0.2, d.y);
                c += star * _StarIntensity * (1 - cover);

                // the moon: a disc and its glow, dimmed behind clouds
                float md = dot(d, normalize(_MoonDirection.xyz));
                float r = radians(_MoonSize) * 0.5;
                float disc = smoothstep(cos(r), cos(r * 0.8), md);
                float glow = exp((md - 1) * _MoonGlowFalloff);
                float3 moon = _MoonColor.rgb * (disc * _MoonIntensity + glow * _MoonGlow) * step(0, d.y);
                c += moon * (1 - cover * 0.85);

                // the clouds themselves: their own colour, lit from below by the horizon glow and at the edge by the moon
                float3 cloud = _CloudColor.rgb + _HorizonGlow.rgb * _CloudGlowFromBelow * (1 - up) + _MoonColor.rgb * glow * _MoonGlow * 4;
                c = lerp(c, cloud, cover);

                return half4(c * _Intensity, 1);
            }
            ENDHLSL
        }
    }
    Fallback Off
}
