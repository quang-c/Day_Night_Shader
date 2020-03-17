Shader "Unlit/SkyboxShader"
{
    Properties
    {
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

			#define HARDNESS_EXPONENT_BASE 0.125

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
				OUT.texcoord = v.texcoord;
                return OUT;
            }

			// sample texture - fragmentshaderinput
			half4 frag(v2f IN) : SV_Target
			{
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

				half3 col = 0;
				col += sunMie * p2 * _LightColor0.rgb; // Sun
				col += lerp(_SkyTint, unity_FogColor, glareMultiplier * glareMultiplier) * p2 * (1 - sunMie); // Sun glare
				col += moonMie * p2 * _MoonColor.rgb; // Moon
				col += unity_FogColor * p1; // Horizon fog
                return half4(col, 1);
            }
            ENDCG
        }
    }
}
