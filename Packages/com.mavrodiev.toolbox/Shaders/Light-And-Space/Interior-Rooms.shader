// Interior Rooms - a flat window that shows a room with depth behind it ("interior mapping").
// What it reads that the Lit shader does not:
//   the view direction -> for each pixel, the line of sight is continued into an imaginary box behind the glass;
//                         where it hits the box (back wall, side wall, floor or ceiling) decides the colour.
// Nothing is behind the window: the room is computed. Move the camera and the walls shift like a real room.
// Each room tile of the surface gets its own walls, lamp (on or off) and back door, chosen by dice rolls.
// Works on any flat surface with UVs; Rooms sets how many windows across and up the UVs hold.

Shader "Mavrodiev/Light-And-Space/Interior-Rooms"
{
    Properties
    {
        _Rooms ("Rooms (across, up)", Vector) = (1, 1, 0, 0)
        _RoomDepth ("Room Depth (m)", Float) = 3
        _WallColor ("Wall Color", Color) = (0.55, 0.52, 0.46, 1)
        _FloorColor ("Floor Color", Color) = (0.22, 0.18, 0.15, 1)
        [HDR] _RoomLight ("Room Light", Color) = (2.2, 1.8, 1.3, 1)
        _LitRooms ("Lit Rooms", Range(0, 1)) = 0.35
        _DarkRooms ("Dark Room Brightness", Range(0, 0.3)) = 0.03
        _Frame ("Frame Width (m)", Range(0, 0.2)) = 0.06
        _FrameColor ("Frame Color", Color) = (0.08, 0.08, 0.08, 1)
        _Smoothness ("Glass Smoothness", Range(0, 1)) = 0.92
        _Seed ("Seed", Float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _Rooms;
            float _RoomDepth;
            half4 _WallColor;
            half4 _FloorColor;
            half4 _RoomLight;
            half _LitRooms;
            half _DarkRooms;
            float _Frame;
            half4 _FrameColor;
            half _Smoothness;
            float _Seed;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include "../Common/Library-Lighting.hlsl"

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
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                half   fogFactor  : TEXCOORD3;
                nointerpolation float seed : TEXCOORD4;   // the same on every pixel (not blended between vertices)
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
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                output.seed = frac(dot(TransformObjectToWorld(float3(0, 0, 0)), float3(0.1031, 0.1130, 0.0973))) * 100.0 + _Seed;
                return output;
            }

            float Dice(float n) { n = frac(n * 0.1031); n *= n + 33.33; n *= n + n; return frac(n); }

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float3 normalWS = normalize(input.normalWS);
                float2 rooms = max(_Rooms.xy, 1.0);
                float2 uvRooms = input.uv * rooms;
                float2 cell = floor(uvRooms);            // which room
                float2 inRoom = frac(uvRooms);           // where in its window, 0..1

                // How many metres one room is wide and tall: measured from how fast the position and the UVs
                // change from one pixel to the next (ddx, ddy), so it fits any size of surface.
                float3 dpx = ddx(input.positionWS), dpy = ddy(input.positionWS);
                float2 duvx = ddx(uvRooms), duvy = ddy(uvRooms);
                float det = duvx.x * duvy.y - duvx.y * duvy.x;
                float3 alongU = (dpx * duvy.y - dpy * duvx.y) / det;   // metres per room, across
                float3 alongV = (dpy * duvx.x - dpx * duvy.x) / det;   // metres per room, up
                float roomW = length(alongU), roomH = length(alongV);
                float3 right = alongU / roomW, up = alongV / roomH;

                // The line of sight, from the camera through this pixel, in the room's own directions
                // (x across, y up, z into the room).
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);   // from the surface towards the camera
                float3 ray = -viewDirWS;
                float3 dir = float3(dot(ray, right), dot(ray, up), dot(ray, -normalWS));
                float3 start = float3(inRoom.x * roomW, inRoom.y * roomH, 0.0);

                // The room is a box: x 0..roomW, y 0..roomH, z 0.._RoomDepth.
                // How far along the ray to each wall it is heading for; the nearest is the one it hits.
                float3 target = float3(dir.x > 0 ? roomW : 0.0, dir.y > 0 ? roomH : 0.0, _RoomDepth);
                float3 dist = (target - start) / dir;
                float hitDist = min(min(dist.x, dist.y), dist.z);
                float3 p = start + dir * hitDist;          // the point it hits, inside the room

                // Dice rolls for this room: is its lamp on, the walls' shade, is there a door in the back wall.
                float roomSeed = input.seed + cell.x * 17.0 + cell.y * 131.0;
                half lit = Dice(roomSeed) < _LitRooms ? 1.0 : 0.0;
                half shade = 0.75 + 0.5 * Dice(roomSeed + 3.3);
                half3 surface; half3 facing;
                if (hitDist == dist.z) { surface = _WallColor.rgb * shade; facing = half3(0, 0, -1); }        // back wall
                else if (hitDist == dist.x) { surface = _WallColor.rgb * shade * 0.85; facing = half3(dir.x > 0 ? -1 : 1, 0, 0); } // side wall
                else if (dir.y < 0) { surface = _FloorColor.rgb; facing = half3(0, 1, 0); }                   // floor
                else { surface = _WallColor.rgb * 1.1; facing = half3(0, -1, 0); }                             // ceiling
                // a doorway in the back wall, in some rooms: a dark opening
                float doorX = 0.25 + 0.5 * Dice(roomSeed + 5.1);
                if (hitDist == dist.z && Dice(roomSeed + 9.2) < 0.5 && abs(p.x / roomW - doorX) < 0.12 && p.y < min(2.1, roomH * 0.8))
                    surface *= 0.08;

                // The room's lamp: a point in the middle of the ceiling. Light falls off with distance,
                // and the corners are a little darker.
                float3 lamp = float3(roomW * 0.5, roomH - 0.05, _RoomDepth * 0.5);
                float3 toLamp = lamp - p;
                half falloff = saturate(dot(normalize(toLamp), facing) * 0.6 + 0.4) * 2.0 / (1.0 + dot(toLamp, toLamp) * 0.35);
                float3 edge = min(p, float3(roomW, roomH, _RoomDepth) - p);
                float corner = min(min(hitDist == dist.x ? 9 : edge.x, hitDist == dist.y ? 9 : edge.y), hitDist == dist.z ? 9 : edge.z);
                half cornerShade = 0.55 + 0.45 * smoothstep(0.0, 0.5, corner);
                half3 room = surface * cornerShade * lerp(_DarkRooms.xxx, _RoomLight.rgb * falloff, lit);
                // the lamp itself, a small bright panel on the ceiling
                if (hitDist == dist.y && dir.y > 0 && abs(p.x - lamp.x) < 0.3 && abs(p.z - lamp.z) < 0.3)
                    room = lerp(room, _RoomLight.rgb * 3.0, lit);

                // The window: a frame round each room, glass in the middle.
                float2 metres = inRoom * float2(roomW, roomH);
                float2 toEdge = min(metres, float2(roomW, roomH) - metres);
                bool frame = min(toEdge.x, toEdge.y) < _Frame;

                InputData inputData = LibraryInputData(input.positionWS, normalWS, input.positionCS, input.fogFactor);
                half4 color;
                if (frame)
                    color = UniversalFragmentPBR(inputData, LibrarySurface(_FrameColor.rgb, 0.3, 0));
                else
                {
                    // glass: reflections from URP's lighting on top, the room seen through it
                    half fresnel = LibraryFresnel(normalWS, viewDirWS, 0.04);
                    color = UniversalFragmentPBR(inputData, LibrarySurface(0, _Smoothness, room * (1.0 - fresnel)));
                }
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return half4(color.rgb, 1);
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

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex LibraryShadowVertex
            #pragma fragment LibraryShadowFragment
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "../Common/Library-Passes.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ZWrite On
            ColorMask R

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
