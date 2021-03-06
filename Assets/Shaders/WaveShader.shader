﻿Shader "Custom/WaveShader"
{
	Properties
	{
		// Predefined properties.
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
	   _Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_Transparency("Opacity", Range(0, 1)) = 1.0


		/* WAVE ATTRIBUTES */
		_Gravity("Gravity", Float) = 9.8
		_Wave_Length("Wave Length", Vector) = (0.75, 0.25, 0.75)
		_Wave_Amplitude("Wave Height", Vector) = (0.1, 0.5, 0.1)
		_Wave_Direction("Wave Direction", Vector) = (0.1, 0, 0.5)
		_BoostWave_Direction("Boost Wave Direction", Vector) = (0, 0, 0)

		   /* WIND WAVE ATTRIBUTES */
		_WindWave_Length("Wind Wave Length", Float) = 0.1
		_WindWave_Amplitude("Wind Wave Amplitude", Float) = 0.5
		_WindWave_Speed("Wind Wave Speed", Float) = 0.85
		_WindWave_Steepness("Wind Wave Steepness", Float) = 2
		_WindWave_Direction("Wind Wave Direction", Vector) = (0, 0, 0)
	}


	SubShader
	{
		   // TODO: Implement opacity code.

		   Tags { "RenderType" = "Opaque" }
		   LOD 200

		   CGPROGRAM
		   #pragma surface surf Standard
		   #pragma vertex vert fullforwardshadows
		   #pragma target 4.0


		   // -------------------------------------------------------------------
		   // HLSL Predefined variables.
		  sampler2D _MainTex;
		  half _Glossiness;
		  half _Metallic;
		  fixed4 _Color;



		  // Water Waves
		  float  _Gravity;
		  float3 _Wave_Length;
		  float3 _Wave_Amplitude;
		  float3 _Wave_Direction;
		  float3 _BoostWave_Direction;


		  // Wind Wave
		  float  _WindWave_Length;
		  float  _WindWave_Amplitude;
		  float  _WindWave_Speed;
		  float  _WindWave_Steepness;
		  float3 _WindWave_Direction;

		  float _WaterTime;



		  // Vertex Input Struct
		  struct Input
		  {
			  float2 uv_MainTex;
		  };

		  // TODO: Implement Ripple code. 
		  // ----------------------- SHADER ------------------------- \\
		  					

		  /*Move the object from current space into world space, calculate the normals and change back. */
		   float3 recalculateNormals(float3 worldPos, float3 xVector, float3 zVector)
		   {
			   // calculate the direction of its normal.
			   float3 vertexNormalLocal = cross(zVector - worldPos, xVector - worldPos);
			   float3 vertexNormalWorld = mul(unity_WorldToObject, vertexNormalLocal);
			   float3 newNormal = normalize(vertexNormalWorld);

			   return newNormal;
		   }


		   float blowWind(float3 worldPos) 
		   {
			   float freq = 2 / _WindWave_Length;
			   float phase = (2 * _WindWave_Speed) / _WindWave_Length;
			   float pinch = _WindWave_Steepness  / (freq *  _WindWave_Amplitude);
			   float dir = dot(_WindWave_Direction.xz, worldPos.xz);

			   float wave = (pinch * _WindWave_Amplitude) * cos((dir - (freq - _WaterTime)) * phase);
			   return wave;
		   }


		   float3 generateWave(float3 worldPos)
		   {
			   float3 windDirection1 = _Wave_Direction;

			   /* Amplitudes */
			   float amplitudeX1 = _Wave_Amplitude.x;
			   float amplitudeY1 = _Wave_Amplitude.y;
			   float amplitudeZ1 = _Wave_Amplitude.z;
			   // ----------------------


			   /* Wave Length */
			   float waveLengthX1 = _Wave_Length.x;
			   float waveLengthY1 = _Wave_Length.y;
			   float waveLengthZ1 = _Wave_Length.z;
			   // ----------------------


			   /* Magnitudes */
			   float magnitudeX1 = (2 * 3.14159274) / waveLengthX1;
			   float magnitudeY1 = (2 * 3.14159274) / waveLengthY1;
			   float magnitudeZ1 = (2 * 3.14159274) / waveLengthZ1;
			   // ----------------------


			   /* Frequencis */
			   float freqX1 = sqrt(_Gravity * magnitudeX1);
			   float freqY1 = sqrt(_Gravity * magnitudeY1);
			   float freqZ1 = sqrt(_Gravity * magnitudeZ1);
			   // ----------------------


			   /* Gerstner Calculations */
			   float waveX1 = ((windDirection1 / magnitudeX1) * amplitudeX1) * sin(dot(windDirection1.xz, worldPos.xz) - (freqX1 * _WaterTime));
			   float waveY1 = amplitudeY1 * cos(dot(windDirection1.xz, worldPos.xz) - (freqY1 - _WaterTime));
			   float waveZ1 = ((windDirection1 / magnitudeZ1) * amplitudeZ1) * sin(dot(windDirection1.xz, worldPos.xz) - (freqZ1 * _WaterTime));
			   // ----------------------


			   float freq  = 2 / 1;
			   float phase = (2 * 0.1) / 1;
			   float pinch = 0.1 / (freq *  0.1);
			   float boosterWave = 0.1 * cos((freq * dot(worldPos.xz, _BoostWave_Direction.xz)) + (phase * _WaterTime));


			   /* Totals */
			   float totalX = waveX1;
			   float totalY = (waveY1 * boosterWave) * blowWind(worldPos);
			   float totalZ = waveZ1;
			   // ----------------------

			   /* Set values */
			   float X = worldPos.x - totalX;
			   float Y = totalY;
			   float Z = worldPos.z - totalZ;
			   // ----------------------

			   return float3(X, Y, Z);
		   }


		   // vertex shader.
		   void vert(inout appdata_full v, out Input o)
		   {
			   UNITY_INITIALIZE_OUTPUT(Input, o);

			   float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

			   float3 xVector = worldPos + float3(0.05, 0, 0);
			   float3 zVector = worldPos + float3(0, 0, 0.05);


			   // New Genster Wave
			   float3 worldPosFinalWater = generateWave(worldPos.xyz);
			   float3  xVectorFinalWater = generateWave(xVector);
			   float3  zVectorFinalWater = generateWave(zVector);


			   worldPos.xyz += worldPosFinalWater;
			   xVector += xVectorFinalWater;
			   zVector += zVectorFinalWater;


			   v.normal = recalculateNormals(worldPos, xVector, zVector);
			   v.vertex.xyz = mul(unity_WorldToObject, worldPos);
		   }



		   void surf(Input IN, inout SurfaceOutputStandard o)
		   {
			   // Albedo comes from a texture tinted by color
			   fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			   o.Albedo = c.rgb;

			   // Metallic and smoothness come from slider variables
			   o.Metallic = _Metallic;
			   o.Smoothness = _Glossiness;
			   o.Alpha = c.a;
		   }
		   ENDCG
	   }
	FallBack "Diffuse"
}

