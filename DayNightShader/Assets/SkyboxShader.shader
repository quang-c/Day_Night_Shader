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
		_MoonTex("Moon Texture", 2D) = "black" {}
		[Space][BloomParameters] _MoonBloomParams("Moon blooming parameters", Vector) = (10.0, -1.0, 0.3, 5.3)

		[Header(Single star settings)]
		_Color("	Star Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[MinMax(0.4, 3.0)] _StarSizeRange("	Star Size Range", Vector) = (0.6, 0.9, 0.0, 0.0)

		[Header(Stars)]
		//[Toggle(ENABLE_STARS)] _EnableStars("Enable Stars", Int) = 1
		_Layers("	Star Layers", Range(1.0, 5.0)) = 5
		_Density("	Star Density", Range(0.5, 4.0)) = 2.28
		_DensityMod("	Star Density Mod", Range(1.1, 3.0)) = 1.95

		[Header(Stars Brightness)]
		_Brightness("	Brightness", Range(0.0, 3.0)) = 2.89
		_BrightnessMod("	Brightness Mod", Range(1.01, 4.0)) = 3.0

		[Header(Clouds)]
		//[Toggle(ENABLE_BACKGROUND_NOISE)] _EnableBackgroundNoise("Enable Clouds", Int) = 1
		_CloudColor("Cloud", Color) = (0.0, 0.33, 0.34, 1.0)
		_NoiseDensity("Noise Density", Range(1.0, 30.0)) = 8.6
		_Speed("Cloud Speed", Range(0.0, 1.0)) = 0.01

		//x - scale					y - iterations				z - amp				w - frequency
		[NoiseParameters] _NoiseParams("Cloud Noise Pattern", Vector) = (0.75, 6.0, 0.795, 2.08)

		//x - scale					y - iterations				z - amp				w - frequency
		[NoiseParameters] _NoiseMaskParams("Cloud Mask", Vector) = (0.33, 6.0, 0.628, 2.11)

		//x - smoothstep.x			y - smoothstep.y			z - spread			w - thickness
		[NoiseCutParameters] _NoiseMaskParams2("Cloud Mask Finetune", Vector) = (0.07, -0.001, 0.51, 2.5)
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

			//#pragma shader_feature _ ENABLE_STARS

			// data
            struct appdata
            {
                float4 vertex : POSITION;
				float3 texcoord :TEXCOORD0;
            };

			// vertex output
			struct v2f
			{
				float4 position : SV_POSITION;  // clip space
				float3 texcoord : TEXCOORD0; // UV data
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

			//#if defined(ENABLE_BACKGROUND_NOISE)
			float4 _CloudColor;
			float _NoiseDensity;
			float4 _NoiseParams;
			float4 _NoiseMaskParams;
			float4 _NoiseMaskParams2;
			float _Speed;
			//#endif

			float4 _MoonBloomParams;
			sampler2D _MoonTex;

			// calc sun or moon shape
			half calculate(half3 sunDirPos, half3 ray, half size, out half distance)
			{
				half3 delta = sunDirPos - ray;
				distance = length(delta);
				half spot = 1.0 - smoothstep(0.0, size, distance);
				return 1.0 - pow(HARDNESS_EXPONENT_BASE, spot * _SunHardness);
			}

			// vertex to fragment - vertex output
            v2f vert (appdata v)
            {
                v2f OUT;
                OUT.position = UnityObjectToClipPos(v.vertex);
				OUT.texcoord = v.texcoord;
                return OUT;
            }

			// creating the stars
			// param sphereRadius = star radius
			// param rayDir  = camera position ray to point
			float stars(float3 rayDir, float sphereRadius, float starSizeMod)
			{
				// create sphere
				float3 spherePoint = rayDir * sphereRadius;
				float angleV = atan2(spherePoint.y, length(spherePoint.xz)) + (2.0 * PI);

				// spread
				float starSpaces = 1.0 / sphereRadius;

				// star size
				float starSize = (sphereRadius * 0.0015) * fwidth(angleV) * 1000.0 * starSizeMod;

				// shift the star spaces vertically
				angleV -= fmod(angleV, starSpaces) - starSpaces * 0.5;

				// number of stars
				float numberOfStars = floor(sqrt(pow(sphereRadius, 2.0) * (1.0 - pow(sin(angleV), 2.0))) * 3.0);

				
				float angleH = atan2(spherePoint.z, spherePoint.x) + 2.0 * PI;
				angleH -= fmod(angleH, PI / numberOfStars);

				float2 randomPosition = random(float2(angleH, angleV) + _Seed);

				float starLevel = sin(angleV + starSpaces * (randomPosition.y - 0.5) * (1.0 - starSize)) * sphereRadius;
				float starDistanceToYAxis = sqrt(sphereRadius * sphereRadius - starLevel * starLevel);
				float starAngle = angleH + (PI * (randomPosition.x * (1.0 - starSize) + starSize * 0.5) / numberOfStars);
				float3 starCenter = float3(cos(starAngle) * starDistanceToYAxis, starLevel, sin(starAngle) * starDistanceToYAxis);

				float star = smoothstep(starSize, 0.0, distance(starCenter, spherePoint));

				return star;
			}

			// lerp size of star based on layer
			// further away means smaller star
			float layerStarMod(float layer)
			{
				return lerp(_StarSizeRange.y, _StarSizeRange.x, smoothstep(1.0, _Layers, layer));
			}


			// sample texture - fragmentshaderinput
			half4 frag(v2f IN) : SV_Target
			{

				float3 rayDir = normalize(IN.texcoord);
				half3 col = half3(0.0, 0.0, 0.0);
				float4 moonCol = float4(0.0, 0.0, 0.0, 0.0);

				// uv y
				half p = IN.texcoord.y;

				half sunDist;
				half moonDist;
				//float moonBloom = pow(smoothstep(_MoonBloomParams.x, _MoonBloomParams.y, length(moonUV.xy - 0.5)), _MoonBloomParams.w) * _MoonBloomParams.z * (dot(rayDir, lightDir) * 0.5 + 0.5);

				// sunlight and moonlight source
				half3 sunMie = calculate(_WorldSpaceLightPos0.xyz, IN.texcoord.xyz, _SunSize, sunDist);
				half3 moonMie = calculate(_MoonPosition.xyz, IN.texcoord.xyz, _MoonSize, moonDist);

				// sun blends with horizon fog when sunrise/sunset
				float p1 = pow(min(1.0, 1.0 - p), _HorizonFogExponent);
				float p2 = 1.0 - p1;

				sunDist =  1- sunDist;
				
				half glareMultiplier = saturate((sunDist - _SunGlareStrength) / (1 - _SunGlareStrength));

				float3 lightDir =  _MoonPosition.xyz;
				float3 rightLightDir = normalize(cross(lightDir, float3(0.0, 1.0, 2.0)));
				float3 upLightDir = cross(rightLightDir, lightDir);

				float3x3 moonMatrix = float3x3(rightLightDir, upLightDir, lightDir);

				float3 moonUV = (mul(moonMatrix, rayDir)) / _MoonSize + float3(0.5, 0.5, 0.0);
				
				

				if (moonUV.x > 0.0 && moonUV.x < 1.0 && moonUV.y > 0.0 && moonUV.y < 1.0 && moonUV.z > 0.0)
				{
					moonCol = tex2D(_MoonTex, moonUV.xyz);
				}

				col += moonCol;

				col += sunMie * p2 * _LightColor0.rgb; // Sun
				col += lerp(_SkyTint, unity_FogColor, glareMultiplier * glareMultiplier) * p2 * (1 - sunMie); // Sun glare

				//col += lerp(col, moonCol, moonCol.a) * _MoonColor;
				//col += moonMie * p2 * _MoonColor; // Moon
				col += unity_FogColor * p1; // Horizon fog

				float star = 0.0;
				// layer the stars
				for (float i = 1; i <= _Layers; i++)
				{
					star += stars(rayDir, _Density * pow(_DensityMod, i), layerStarMod(i)) * (1.0 / pow(_BrightnessMod, i));
				}

				half3 skyColor = _SkyTint;

				//#if defined(ENABLE_BACKGROUND_NOISE)
				
				float3 posi = rayDir * _NoiseDensity + _Seed; //uv coords

				float noise = layeredNoise(posi * _NoiseParams.x , _NoiseParams.y, _NoiseParams.z, _NoiseParams.w); // base noise
				float noise2 = layeredNoise(posi * _NoiseMaskParams.x * 0.05 + 21.32 + (_Time.y * _Speed), _NoiseMaskParams.y, _NoiseMaskParams.z , _NoiseMaskParams.w); // noise2
				noise2 = pow(smoothstep(_NoiseMaskParams2.x , _NoiseMaskParams2.y , abs(noise2  - _NoiseMaskParams2.z )), _NoiseMaskParams2.w ); // finetune noise2
				skyColor += _CloudColor * noise2 * noise ;
				//#endif

				col += _Color * star * _Brightness + skyColor;
                return half4(col, 1);
            }
            ENDCG
        }
    }
}
