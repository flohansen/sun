﻿Shader "Unlit/SunShader"
{
    Properties
    {
        _amplitude ("amplitude", Float) = 0.05
        _waveSpeed ("waveSpeed", Float) = 10.0
        _frequency ("frequency", Float) = 100.0
        _color1 ("brightSpots", Color) = (0,0,0,1)
        _color2 ("darkSpots", Color) = (1,0,0,1)
        _octaves ("Octaves", Int) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float4 _color1, _color2;
            float _amplitude, _waveSpeed, _frequency;
            int _octaves;

            float hash (float2 n)
            {
              return frac(sin(dot(n,float2(123.456789,987.654321)))*54321.9876 );
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 u = smoothstep(0.0,1.0,frac(p));
                float a = hash(i+float2(0,0));
                float b = hash(i+float2(1,0));
                float c = hash(i+float2(0,1));
                float d = hash(i+float2(1,1));
                float r = lerp(lerp(a,b,u.x), lerp(c,d,u.x),u.y);
                return r*r;
            }

            float fbm(float2 p , int octaves)
            {
                float value = 0.0;
                float amplitude = 0.45;
                float e = 4.0;

                for (int i = 0; i < octaves; i++)
                {
                    value += amplitude * noise(p);
                    p = p * e;
                    amplitude *= 0.55;
                    e *= 0.85;
                }

                return value;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {

                float3 position = v.vertex.xyz;
                float3 direction = normalize(position);

                //waves with sinus / cosinus frequency on surface
                position.x += direction.x * _amplitude * sin(_Time * _waveSpeed + position.x * _frequency);
                position.y += direction.y * _amplitude * cos(_Time * _waveSpeed + position.y * _frequency);
                position.z += direction.z * _amplitude * sin(_Time * _waveSpeed + position.z * _frequency);

                v2f o;
                //new position for o.vertex
                o.vertex = UnityObjectToClipPos(float4(position, 1.0));
                o.uv = v.uv;

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
              float2 uv = i.uv.xy;

              float f = fbm(uv + fbm(5 * uv + _Time.x, _octaves), _octaves);
              float4 color = lerp(_color1, _color2, 2*f);

              return color;
            }
            ENDCG
        }
    }
}
