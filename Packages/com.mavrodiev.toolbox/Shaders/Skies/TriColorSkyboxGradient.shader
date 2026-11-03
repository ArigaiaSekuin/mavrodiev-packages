Shader "Mavrodiev/Skies/TriColorSkyboxGradient"
{
    Properties
    {
        _GroundColor ("Ground Color", Color) = (0.4, 0.4, 0.5, 1.0)
        _HorizonColor ("Horizon Color", Color) = (0.9, 0.85, 0.8, 1.0)
        _ZenithColor ("Zenith Color", Color) = (0.15, 0.35, 0.65, 1.0)
        
        _HorizonHeight ("Horizon Height", Range(-0.5, 0.5)) = 0.0
        _HorizonFalloff ("Horizon Falloff", Range(0.1, 10.0)) = 2.5
        
        _GroundBlend ("Ground Blend Range", Range(0.01, 1.0)) = 0.3
        _ZenithBlend ("Zenith Blend Range", Range(0.01, 1.0)) = 0.4
        
        _GroundOffset ("Ground Offset", Range(-0.5, 0.5)) = -0.1
        _ZenithOffset ("Zenith Offset", Range(-0.5, 0.5)) = 0.1
    }
    
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off
        ZWrite Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            
            // Use fixed precision for mobile optimization
            #pragma fragmentoption ARB_precision_hint_fastest
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
            };
            
            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed3 viewDir : TEXCOORD0;
            };
            
            // Colors
            fixed4 _GroundColor;
            fixed4 _HorizonColor;
            fixed4 _ZenithColor;
            
            // Controls
            fixed _HorizonHeight;
            fixed _HorizonFalloff;
            fixed _GroundBlend;
            fixed _ZenithBlend;
            fixed _GroundOffset;
            fixed _ZenithOffset;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // Calculate world space view direction
                float3 viewDir = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
                o.viewDir = normalize(viewDir);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Get the Y component of view direction
                fixed y = i.viewDir.y + _HorizonHeight;
                
                // Calculate blend factors for each transition
                
                // Ground to Horizon blend
                fixed groundToHorizon = saturate((y - _GroundOffset) / _GroundBlend);
                groundToHorizon = pow(groundToHorizon, _HorizonFalloff);
                
                // Horizon to Zenith blend  
                fixed horizonToZenith = saturate((y - _ZenithOffset) / _ZenithBlend);
                horizonToZenith = pow(horizonToZenith, 1.0 / _HorizonFalloff);
                
                // Three-way blend
                fixed4 groundHorizonMix = lerp(_GroundColor, _HorizonColor, groundToHorizon);
                fixed4 finalColor = lerp(groundHorizonMix, _ZenithColor, horizonToZenith);
                
                return finalColor;
            }
            ENDCG
        }
    }
    
    Fallback Off
}