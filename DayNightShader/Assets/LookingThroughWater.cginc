// this include file is used for creating fog under water that gives you a sense of depth (underwater light absorption)

#if !defined(LOOKING_THROUGH_WATER_INCLUDED)
#define LOOKING_THROUGH_WATER_INCLUDED

sampler2D _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;

sampler2D _WaterBackground;

// control fog
float3 _WaterFogColor;
float _WaterFogDensity;

// because we're going to change the color of whatever is below the water surface
// we can no longer rely on the default transparent blending of the standard shader
float3 ColorBelowWater(float4 screenPos)
{
	// depth texture coordinates
	float2 uv = screenPos.xy / screenPos.w;

	// check if texel size of camera depth texture is negative in the V dimension
	// if so, invert the V coordinate
	#if UNITY_UV_STARTS_AT_TOP
		if (_CameraDepthTexture_TexelSize.y < 0) {
			uv.y = 1 - uv.y;
		}
	#endif


	// depth between bottom of sea to screen
	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	// depth between water surface and screen
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	// underwater depth
	float depthDifference = backgroundDepth - surfaceDepth;
	
	float3 backgroundColor = tex2D(_WaterBackground, uv).rgb;

	// calculate fog density based on depth
	float fogFactor = exp2(-_WaterFogDensity * depthDifference);
	return lerp(_WaterFogColor, backgroundColor, fogFactor);;
}

#endif