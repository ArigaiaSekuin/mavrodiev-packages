Shader "Mavrodiev/Surfaces/Simple-Toon-Outline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Colorize)][Space(5)]
        _Color ("Color", COLOR) = (1,1,1,1)

        [HideInInspector] _ColIntense ("Intensity", Range(0,3)) = 1
        [HideInInspector] _ColBright ("Brightness", Range(-1,1)) = 0
        _AmbientCol ("Ambient", Range(0,1)) = 0

        [Header(Detail)][Space(5)]
        [Toggle] _Segmented ("Segmented", Float) = 1
        _Steps ("Steps", Range(1,25)) = 3
        _StpSmooth ("Smoothness", Range(0,1)) = 0
        _Offset ("Lit Offset", Range(-1,1.1)) = 0

        [Header(Light)][Space(5)]
        [Toggle] _Clipped ("Clipped", Float) = 0
        _MinLight ("Min Light", Range(0,1)) = 0
        _MaxLight ("Max Light", Range(0,1)) = 1
        _Lumin ("Luminocity", Range(0,2)) = 0

        [Header(Outline)][Space(5)]
        _OtlColor ("Color", COLOR) = (0,0,0,1)
        _OtlWidth ("Width", Range(0,5)) = 1

        [Header(Shine)][Space(5)]
        [HDR] _ShnColor ("Color", COLOR) = (1,1,0,1)
        [Toggle] _ShnOverlap ("Overlap", Float) = 0

        _ShnIntense ("Intensity", Range(0,1)) = 0
        _ShnRange ("Range", Range(0,1)) = 0.15
        _ShnSmooth ("Smoothness", Range(0,1)) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "STCore.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(o.worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float maxLight = max(_MinLight, _MaxLight);
                float steps = _Segmented > 0.5 ? _Steps : 1;
                float stpSmooth = _Segmented > 0.5 ? _StpSmooth : 1;
                float maxAtten = 1.0;

                float3 normal = normalize(i.worldNormal);
                float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 forward = mul((float3x3)UNITY_MATRIX_I_V, float3(0,0,1));

                // Main light
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                Light mainLight = GetMainLight(shadowCoord);

                float3 light_dir = normalize(mainLight.direction);
                float3 halfVec = normalize(light_dir + view_dir);

                float NdotL = dot(normal, light_dir);
                float NdotH = dot(normal, halfVec);
                float VdotN = dot(view_dir, normal);
                float FdotV = dot(forward, -view_dir);

                half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
                float toon = Toon(NdotL, atten, _MinLight, maxLight, steps, stpSmooth, _Offset, _Clipped, _Lumin, maxAtten);

                half4 lightColor = half4(mainLight.color, 1.0);
                half4 shadecol = half4(0,0,0,1);
                half4 litcol = ColorBlend(_Color, lightColor, _AmbientCol);
                half4 texcol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * litcol * _ColIntense + _ColBright;

                float4 blendCol = ColorBlend(shadecol, texcol, toon);
                float4 result = PostEffects(blendCol, toon, atten, NdotL, NdotH, VdotN, FdotV, maxAtten);
                result.a = 1.0;

                float mainLightActive = dot(mainLight.color, half3(1,1,1)) > 0 ? 1.0 : 0.0;
                result *= mainLightActive;

                // Additional lights
                uint additionalLightsCount = GetAdditionalLightsCount();
                for (uint j = 0u; j < additionalLightsCount; j++)
                {
                    Light addLight = GetAdditionalLight(j, i.worldPos);

                    float3 add_dir = normalize(addLight.direction);
                    float3 add_halfVec = normalize(add_dir + view_dir);

                    float add_NdotL = dot(normal, add_dir);
                    float add_NdotH = dot(normal, add_halfVec);

                    half add_atten = addLight.distanceAttenuation * addLight.shadowAttenuation;
                    float add_toon = Toon(add_NdotL, add_atten, _MinLight, maxLight, steps, stpSmooth, _Offset, _Clipped, _Lumin, maxAtten);

                    half4 add_lightColor = half4(addLight.color, 1.0);
                    half4 add_litcol = ColorBlend(_Color, add_lightColor, _AmbientCol);
                    half4 add_texcol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * add_litcol * _ColIntense + _ColBright;

                    float4 add_blendCol = ColorBlend(shadecol, add_texcol, add_toon);
                    float4 add_postCol = PostEffects(add_blendCol, add_toon, add_atten, add_NdotL, add_NdotH, VdotN, FdotV, maxAtten);
                    add_postCol.a = 1.0;

                    result = max(result, add_postCol);
                }

                return result;
            }

            ENDHLSL
        }

        // Outline pass
        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "SRPDefaultUnlit" }

            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "STFunctions.hlsl"

            float4 _OtlColor;
            float _OtlWidth;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float4 pos = v.vertex;
                pos.xyz += normalize(v.normal.xyz) * _OtlWidth * 0.008;
                o.pos = TransformObjectToHClip(pos.xyz);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                clip(-negz(_OtlWidth));
                return _OtlColor;
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
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                float4 clipPos = TransformWorldToHClip(ApplyShadowBias(worldPos, worldNormal, _LightDirection));

                #if UNITY_REVERSED_Z
                    clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                o.pos = clipPos;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return 0;
            }

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
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return 0;
            }

            ENDHLSL
        }
    }
}
