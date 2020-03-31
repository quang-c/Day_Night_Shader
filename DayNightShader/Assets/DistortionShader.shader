Shader "Unlit/DistortionShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity("Water Fog Density", Range(0, 2)) = 0.1
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0

		[NoScaleOffset] _FlowMap("Flow (RG, A noise)", 2D) = "black" {}
		[NoScaleOffset] _DerivHeightMap("Deriv (AG) Height (B)", 2D) = "black" {}

		_UJump("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling("Tiling", Float) = 1
		_Speed("Speed", Float) = 1
		_FlowStrength("Flow Strength", Float) = 1
		_FlowOffset("Flow Offset", Float) = 0
		_HeightScale("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated("Height Scale, Modulated", Float) = 0.75
	}
		SubShader
		{
			// making the texture adjustable in transparency ( alpha in surface #pragma below)
			Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
			LOD 200

			// use grabpass to retrieve color of the bottom of the sea
			// before rendering the water
			GrabPass
			{
				"_WaterBackground"
			}

			CGPROGRAM
			#pragma surface surf Standard alpha finalcolor:ResetAlpha

			#pragma target 3.0

			// include some cginc files
			#include "Flow.cginc"
			#include "LookingThroughWater.cginc"

			sampler2D _MainTex;
			sampler2D _FlowMap;
			sampler2D _DerivHeightMap;

			float3 UnpackDerivativeHeight(float4 textureData) {
				float3 dh = textureData.agb;
				dh.xy = dh.xy * 2 - 1;
				return dh;
			}



			// phase jumping for more unique patterns
			float _UJump;
			float _VJump;

			// regular tiling
			float _Tiling;
			// movement speed of the water
			float _Speed;

			// flowStrength = flow of the water, if 0 then its stationary water
			float _FlowStrength;
			float _FlowOffset;

			// low flow = small height(waves), high flow = big height ( waves)
			float _HeightScale;
			float _HeightScaleModulated;

			struct Input
			{
				float2 uv_MainTex;
				float4 screenPos;
			};

			half _Glossiness;
			half _Metallic;
			fixed4 _Color;

			void surf(Input IN, inout SurfaceOutputStandard o)
			{
				// flow map calculations
				float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
				flow.xy = flow.xy * 2 - 1;
				flow *= _FlowStrength;
				float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
				float time = _Time.y * _Speed + noise;
				float2 jump = float2(_UJump, _VJump);

				// 2 distortions, A and B for maximum effect, they phase offset each other so they appear one after another
				float3 uvwA = FlowUVW(IN.uv_MainTex, flow.xy, jump, _FlowOffset, _Tiling, time, false);
				float3 uvwB = FlowUVW(IN.uv_MainTex, flow.xy, jump, _FlowOffset, _Tiling, time, true);

				// calculate final height
				float finalHeightScale = length(flow.z) * _HeightScaleModulated + _HeightScale;

				// derivative height map instead of using normal map because its cheaper
				// used for creating height effects in the texture
				float3 dhA = UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwA.xy)) * (uvwA.z * finalHeightScale);
				float3 dhB = UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) * (uvwB.z * finalHeightScale);
				o.Normal = normalize(float3(-(dhA.xy + dhB.xy), 1));

				// z = weight
				// sample texture twice
				fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
				fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

				fixed4 c = (texA + texB) * _Color;

				o.Albedo = c.rgb;
				o.Metallic = _Metallic;
				o.Smoothness = _Glossiness;
				o.Alpha = c.a;

				// using emission so that the fog will be added to the surface lighting
				// and won't be the albedo surface (because that's affected by lighting)
				o.Emission = ColorBelowWater(IN.screenPos) * (1 - c.a);
			}

			// reset alpha when last fragment color has been calculated
			void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color) {
				color.a = 1;
			}
			ENDCG
		}
}
