Shader "Unlit/SkyboxShader"
{
    Properties
    {
		_Seed("Seed", float) = 68.89
		_SkyTint("Sky Tint", Color) = (.5, .5, .5, 1)
		_HorizonFogExponent("Horizon Fog", Range(0, 15)) = 1

		[Header(Sun)]
		_SunSize("	Size", Range(0,1)) = 0.04
		_SunHardness("	Hardness", Float) = 0.1
		_SunGlareStrength("	Glare Strength", Range(0, 1)) = 0.5

		[Header(Moon)]
		_MoonColor("	Color", Color) = (1, 1, 1, 1)
		_MoonPosition("	Position", Vector) = (0, 0, 1)
		_MoonSize("	Size", Range(0, 1)) = 0.03

		[Header(Single star settings)]
		_Color("	Stars color", Color) = (1.0, 1.0, 1.0, 1.0)
		[MinMax(0.4, 3.0)] _StarSizeRange("	Star size range", Vector) = (0.6, 0.9, 0.0, 0.0)

		[Header(Stars)]
		[Toggle(ENABLE_STARS)] _EnableStars("Enable Stars", Int) = 1
		_Layers("	Star Layers", Range(1.0, 5.0)) = 5
		_Density("	Star Density", Range(0.5, 4.0)) = 2.28
		_DensityMod("	Star Density modulation", Range(1.1, 3.0)) = 1.95

		[Header(Brightness settings)]
		_Brightness("Contrast", Range(0.0, 3.0)) = 2.89
		_BrightnessMod("Brightness modulation", Range(1.01, 4.0)) = 3.0
    }
    SubShader
    {
        Tags { "RenderType"="Skybox" "Queue"="Background" }
        Zwrite Off
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "Utils.cginc"

			#define HARDNESS_EXPONENT_BASE 0.125
			#define PI 3.141592653589793238462

			#pragma shader_feature _ ENABLE_STARS

			// data
            struct appdata
            {
                float4 vertex : POSITION;
				float3 texcoord :TEXCOORD0;
            };

			// vertex to fragment struct
			struct v2f
			{
				float4 position : SV_POSITION;
				float3 texcoord : TEXCOORD0;
			};

			// uniform: a variable whose data is constant throughout the execution of a shader
			//(such as a material color in a vertex shader) global variables are considered uniform by default
			// half = medium precision floating point
			// half3 = medium precision 3D vector with x,y,z components (also for color: r,g,b)
			uniform float3 _MoonPosition;
			uniform half3 _SkyTint, _MoonColor;
			uniform half _SunSize, _HorizonFogExponent, _SunHardness, _SunGlareStrength, _MoonSize;

			float _Seed;
			float4 _Color;
			float2 _StarSizeRange;
			float _Density;
			float _Layers;
			float _DensityMod;
			float _BrightnessMod;
			float _Brightness;

			// calc sun or moon shape
			half calculate(half3 sunDirPos, half3 ray, half size, out half distance)
			{
				half3 delta = sunDirPos - ray;
				distance = length(delta);
				half spot = 1.0 - smoothstep(0.0, size, distance);
				return 1.0 - pow(HARDNESS_EXPONENT_BASE, spot * _SunHardness);
			}

			// vertex to fragment - vertexshaderoutput
            v2f vert (appdata v)
            {
                v2f OUT;
                OUT.position = UnityObjectToClipPos(v.vertex);
				OUT.texcoord = v.texcoord.xyz;
				//OUT.texcoord = v.texcoord;
                return OUT;
            }

			float stars(float3 rayDir, float sphereRadius, float sizeMod)
			{
				float3 spherePoint = rayDir * sphereRadius;

				float upAtan = atan2(spherePoint.y, length(spherePoint.xz)) + 4.0 * PI;

				float starSpaces = 1.0 / sphereRadius;
				float starSize = (sphereRadius * 0.0015) * fwidth(upAtan) * 1000.0 * sizeMod;
				upAtan -= fmod(upAtan, starSpaces) - starSpaces * 0.5;

				float numberOfStars = floor(sqrt(pow(sphereRadius, 2.0) * (1.0 - pow(sin(upAtan), 2.0))) * 3.0);

				float planeAngle = atan2(spherePoint.z, spherePoint.x) + 4.0 * PI;
				planeAngle = planeAngle - fmod(planeAngle, PI / numberOfStars);

				float2 randomPosition = hash22(float2(planeAngle, upAtan) + _Seed);

				float starLevel = sin(upAtan + starSpaces * (randomPosition.y - 0.5) * (1.0 - starSize)) * sphereRadius;
				float starDistanceToYAxis = sqrt(sphereRadius * sphereRadius - starLevel * starLevel);
				float starAngle = planeAngle + (PI * (randomPosition.x * (1.0 - starSize) + starSize * 0.5) / numberOfStars);
				float3 starCenter = float3(cos(starAngle) * starDistanceToYAxis, starLevel, sin(starAngle) * starDistanceToYAxis);

				float star = smoothstep(starSize, 0.0, distance(starCenter, spherePoint));

				return star;
			}

			float starModFromI(float i)
			{
				return lerp(_StarSizeRange.y, _StarSizeRange.x, smoothstep(1.0, _Layers, i));
			}


			// sample texture - fragmentshaderinput
			half4 frag(v2f IN) : SV_Target
			{


				half3 col = half3(0.0, 0.0, 0.0);


				// uv y
				half p = IN.texcoord.y;

				half sunDist;
				half moonDist;
				// sunlight and moonlight scattering
				half3 sunMie = calculate(_WorldSpaceLightPos0.xyz, IN.texcoord.xyz, _SunSize, sunDist);
				half3 moonMie = calculate(_MoonPosition.xyz, IN.texcoord.xyz, _MoonSize, moonDist);

				// sun blends with horizon fog when sunrise/sunset
				float p1 = pow(min(1.0, 1.0 - p), _HorizonFogExponent);
				float p2 = 1.0 - p1;

				sunDist =  1- sunDist;

				
				half glareMultiplier = saturate((sunDist - _SunGlareStrength) / (1 - _SunGlareStrength));



				col += sunMie * p2 * _LightColor0.rgb; // Sun
				col += lerp(_SkyTint, unity_FogColor, glareMultiplier * glareMultiplier) * p2 * (1 - sunMie); // Sun glare
				col += moonMie * p2 * _MoonColor.rgb; // Moon
				col += unity_FogColor * p1; // Horizon fog

				#if defined(ENABLE_STARS)
				float3 rayDir = normalize(IN.texcoord - _WorldSpaceCameraPos);
				float star = 0.0;
				for (float i = 1.0; i <= _Layers; i += 1.0)
				{
					star += stars(rayDir, _Density * pow(_DensityMod, i), starModFromI(i)) * (1.0 / pow(_BrightnessMod, i));
				}


				col += _Color * star * _Brightness;

				#endif

                return half4(col, 1);
            }
            ENDCG
        }
    }
}
