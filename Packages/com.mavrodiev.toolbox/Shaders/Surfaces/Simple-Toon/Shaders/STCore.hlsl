#ifndef STCORE_INCLUDED
#define STCORE_INCLUDED

#include "STFunctions.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
float4 _MainTex_ST;

float4 _Color;
float4 _DarkColor;
float _AmbientCol;
float _ColIntense;
float _ColBright;

float _Segmented;
float _Steps;
float _StpSmooth;
float _Offset;

float _Clipped;
float _MinLight;
float _MaxLight;
float _Lumin;

float _MaxAtten;

float4 _ShnColor;
float _ShnOverlap;
float _ShnIntense;
float _ShnRange;
float _ShnSmooth;

float Toon (float dot_v, half atten, float minLight, float maxLight, float steps, float stpSmooth, float offset, float clipped, float lumin, float maxAtten)
{
	float o = clamp(offset, -1, 1);
	float delta = maxLight - minLight;

	//intense
	float ints_pls = dot_v + o;
	float ints_max = 1.0 + o;
	float intense = clamp01(ints_pls / ints_max);

	//lit
	float stp = 1.0 / floor(steps);
	int lit_num = ceil(intense / stp);
	float lit = lit_num * stp;

	//smooth
	float reduce_v = o - 1.0;
	float reduce_res = 1.0 - clamp01(reduce_v / 0.1);
	float reduce = lit_num == 1 ? reduce_res : 1;

	float smth_start = lit - stp;
	float smth_end = smth_start + stp * stpSmooth;

	float smth_lrp = invLerp01(smth_end, smth_start, intense, 0.0);
	float smth_stp = smoothstepSafe(smth_end, smth_start, intense, 0.0);

	float smooth_v = smoothlerp(smth_stp, smth_lrp, stpSmooth);
	float smooth_r = clamp01(lit - smooth_v * reduce * stp);

	//shadow
	float atten_inv = clamp(atten, 1.0 - maxAtten, 1);
	float dimLit = smooth_r * atten_inv;
	float dim_dlt = dimLit - minLight;

	//luminocity
	float lumLight = maxLight + lumin;
	float lum_dlt = lumLight - minLight;

	//clipped
	float litd_clmp = clamp01(dim_dlt);
	float clip_cf = litd_clmp / delta;

	float clip_uncl = minLight + clip_cf * lum_dlt;
	float clip_v = clamp(clip_uncl, minLight, lumLight);

	//relative limits
	float lerp_v = lum_dlt * dimLit;
	float relate_v = minLight + lerp_v;

	//result
	float result = clipped * clip_v;
	result += (1.0 - clipped) * relate_v;

	return result;
}

//post effects

void PostShine (inout float4 col, float dot_v, float atten, float maxAtten)
{
	float p = abs(dot_v - 1.0);
	float len = _ShnRange * 2;

	float smth_inv = 1.0 - _ShnSmooth;
	float smth_end = len * smth_inv;

	float shine = posz(len - p);
	float smooth_v = smoothstepSafe(len, smth_end, p, 1.0);
	float dim = 1.0 - maxAtten * rev(atten) * rev(_ShnOverlap);

	float blend = _ShnIntense * shine * smooth_v * dim;
	col = ColorBlend(col, _ShnColor, blend);
}

float4 PostEffects (float4 col, float toon, float atten, float NdotL, float NdotH, float VdotN, float FdotV, float maxAtten)
{
	PostShine(col, NdotL, atten, maxAtten);

	return col;
}

#endif
