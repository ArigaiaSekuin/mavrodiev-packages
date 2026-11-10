// FoliageWind.hlsl
// The toolbox, Shaders. Petar's, written 2026-11-10 with an AI assistant.
// The wind for "Mavrodiev/Foliage Wind": it moves each vertex before URP's own Lit passes run.
// The higher a vertex is above the object's pivot, the more it moves: the roots stay put, the tips sway.

#ifndef MAVRODIEV_FOLIAGE_WIND_INCLUDED
#define MAVRODIEV_FOLIAGE_WIND_INCLUDED

// The five _Wind settings are declared in FoliageLitInput.hlsl, inside the material's constant buffer.

float3 FoliageWindOffsetOS(float3 positionOS)
{
    float3 pivotWS = GetObjectToWorldMatrix()._m03_m13_m23;
    float3 positionWS = TransformObjectToWorld(positionOS);

    float2 dir = _WindDirection.xz;
    dir = dot(dir, dir) > 1e-4 ? normalize(dir) : float2(1, 0);

    // How much this vertex bends: 0 at the pivot, 1 at Bend Height, curved so the base stays stiff.
    float height = max(positionWS.y - pivotWS.y, 0) / max(_WindBendHeight, 0.01);
    float bend = saturate(height);
    bend *= bend;

    // A slow gust that travels across the ground, and a quicker flutter on top of it.
    float t = _Time.y * _WindSpeed;
    float travel = dot(pivotWS.xz, dir) / max(_WindGustSize, 0.1);
    float gust = 0.6 + 0.4 * sin(t * 0.7 - travel * 6.2832);
    float sway = sin(t * 2.0 - travel * 6.2832 + pivotWS.x * 0.37) * 0.5 + 0.5;
    float flutter = sin(t * 5.3 + dot(positionWS, float3(1.7, 2.3, 1.1))) * 0.15;

    float amount = _WindStrength * bend * (gust * sway + flutter);
    float3 offsetWS = float3(dir.x, 0, dir.y) * amount;
    offsetWS.y = -0.3 * abs(amount) * bend;   // tips dip a little as they bend

    return positionOS + TransformWorldToObjectDir(offsetWS, false);
}

#if defined(MAVRODIEV_WIND_FORWARD)
Varyings WindLitPassVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    input.positionOS.xyz = FoliageWindOffsetOS(input.positionOS.xyz);
    return LitPassVertex(input);
}
#endif

#if defined(MAVRODIEV_WIND_SHADOW)
Varyings WindShadowPassVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    input.positionOS.xyz = FoliageWindOffsetOS(input.positionOS.xyz);
    return ShadowPassVertex(input);
}
#endif

#if defined(MAVRODIEV_WIND_GBUFFER)
Varyings WindLitGBufferPassVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    input.positionOS.xyz = FoliageWindOffsetOS(input.positionOS.xyz);
    return LitGBufferPassVertex(input);
}
#endif

#if defined(MAVRODIEV_WIND_DEPTH)
Varyings WindDepthOnlyVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    input.position.xyz = FoliageWindOffsetOS(input.position.xyz);
    return DepthOnlyVertex(input);
}
#endif

#if defined(MAVRODIEV_WIND_DEPTHNORMALS)
Varyings WindDepthNormalsVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    input.positionOS.xyz = FoliageWindOffsetOS(input.positionOS.xyz);
    return DepthNormalsVertex(input);
}
#endif

#endif
