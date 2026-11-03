// Glow Volume - the halo of haze around a lamp, without volumetric fog (Light-And-Space family).
// DRAFT for the builder: install at Assets/_Staging/com.mavrodiev.toolbox/Shaders/Light-And-Space/Glow-Volume.shader
// Put it on a sphere (Unity's Sphere: radius 0.5 in its own space) centred on the lamp; scale the sphere to the
// size of the halo. Uniform scale only (the X scale is read).
//
// What it reads:
//   the sphere's centre and size   -> where the haze is, in the world
//   the camera's position          -> the ray through each pixel, so the halo is a real volume:
//                                     each eye in VR sees it from its own position
//   the depth behind it            -> the ray stops at the first surface, so a wall in front of the lamp
//                                     hides the haze, and the haze does not show through the floor
//                                     (needs Depth Texture on in the URP Asset; on in PC_RPAsset)
// The haze along each ray is computed exactly, not sampled: the density is 1 / (r^2 + c^2), minus its value
// at the sphere's edge, so it fades to zero at the surface (no hard outline), and c (Core Size) keeps the centre
// from becoming infinite. The result is scaled so a ray through the centre gives 1.
// It reads no lights and no shadows: it is an added colour, like Fake-Beam. It casts no shadow and writes no depth.

Shader "Mavrodiev/Light-And-Space/Glow-Volume"
{
    Properties
    {
        [HDR] _Color ("Color", Color) = (1, 0.55, 0.2, 1)
        _Intensity ("Intensity", Range(0, 4)) = 1
        _Core ("Core Size (part of the radius)", Range(0.02, 1)) = 0.2
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }

        Pass
        {
            Name "ForwardUnlit"
            Tags { "LightMode" = "UniversalForward" }

            // Added to what is behind. The back faces are drawn, so the halo still shows when the camera is inside it;
            // the depth test is done by hand (the ray is cut at the scene's depth), so ZTest is Always.
            Blend One One
            ZWrite Off
            ZTest Always
            Cull Front

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _Intensity;
                half _Core;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 sphere     : TEXCOORD1;   // xyz: the centre in the world, w: the radius in metres
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings Vertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                float3 centreWS = TransformObjectToWorld(float3(0, 0, 0));
                float scale = length(TransformObjectToWorldDir(float3(1, 0, 0), false));
                output.sphere = float4(centreWS, 0.5 * scale);
                return output;
            }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // 1. The ray from this eye through this pixel, and where it enters and leaves the sphere.
                float3 cameraWS = GetCameraPositionWS();
                float3 rayDir = normalize(input.positionWS - cameraWS);
                float3 toCentre = input.sphere.xyz - cameraWS;
                float radius = input.sphere.w;
                float along = dot(toCentre, rayDir);                       // distance to the point nearest the centre
                float h2 = max(dot(toCentre, toCentre) - along * along, 0.0); // squared distance of the ray from the centre
                float r2 = radius * radius;
                if (h2 >= r2)
                    return 0;
                float halfChord = sqrt(r2 - h2);
                float t0 = max(along - halfChord, 0.0);                    // 0 when the camera is inside
                float t1 = along + halfChord;

                // 2. Stop at the first surface: the scene's depth, as a distance along the same ray.
                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                float rawDepth = SampleSceneDepth(screenUV);
                float3 sceneWS = ComputeWorldSpacePosition(screenUV, rawDepth, UNITY_MATRIX_I_VP);
                t1 = min(t1, dot(sceneWS - cameraWS, rayDir));
                if (t1 <= t0)
                    return 0;

                // 3. The haze between t0 and t1, integrated exactly:
                //    integral of 1/(h^2 + s^2 + c^2) - 1/(R^2 + c^2) ds  =  atan(s/k)/k - s/(R^2 + c^2),  k^2 = h^2 + c^2
                float c = max(_Core, 0.02) * radius;
                float c2 = c * c;
                float k = sqrt(h2 + c2);
                float edge = 1.0 / (r2 + c2);
                float s0 = t0 - along;
                float s1 = t1 - along;
                float haze = (atan(s1 / k) - atan(s0 / k)) / k - (s1 - s0) * edge;
                float throughCentre = 2.0 * atan(radius / c) / c - 2.0 * radius * edge;
                haze = saturate(haze / throughCentre);

                half3 color = _Color.rgb * _Intensity * haze;

                // Distance fog fades an added colour toward black (nothing added), measured at the middle of the segment.
                float4 middleCS = TransformWorldToHClip(cameraWS + rayDir * (0.5 * (t0 + t1)));
                color = MixFogColor(color, half3(0, 0, 0), ComputeFogFactor(middleCS.z));
                return half4(color, 1);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
