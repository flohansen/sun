﻿Shader "Unlit/SunShader"
{
    Properties
    {
      [Header(Fractal Brownian Motion)] [Space]
      _fbmAmplitude("Amplitude", Float) = 0.45
      _fbmGranularity("Granularity", Float) = 4.0

      [Header(Procedural Texture)][Space]
      _displacement("Displacement", Float) = 0.01
      _color1("Bright Color", Color) = (0,0,0,1)
      _color2("Dark Color", Color) = (1,0,0,1)
      _color3("Bright Color 2", Color) = (0,0,0,1)
      _color4("Dark Color 2", Color) = (1,0,0,1)
      _octaves("Octaves", Int) = 4

      _ZoomVal("ZoomValue", Float) = 5.0
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 _color1;
            float4 _color2;
            float4 _color3;
            float4 _color4;
            float _displacement;
            float _fbmAmplitude;
            float _fbmGranularity;
            float _ZoomVal;
            int _octaves;

            float hash(float2 n)
            {
              return frac(sin(dot(n,float2(123.456789,987.654321))) * 54321.9876);
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 u = smoothstep(0.0,1.0,frac(p));
                float a = hash(i + float2(0,0));
                float b = hash(i + float2(1,0));
                float c = hash(i + float2(0,1));
                float d = hash(i + float2(1,1));
                float r = lerp(lerp(a,b,u.x), lerp(c,d,u.x),u.y);
                return r * r;
            }

            float fbm(float2 p , int octaves)
            {
                float value = 0.0;
                float amplitude = _fbmAmplitude;
                float e = _fbmGranularity;

                for (int i = 0; i < octaves; i++)
                {
                    value += amplitude * noise(p);
                    p = p * e;
                    amplitude *= 0.55;
                    e *= 0.85;
                }

                return value;
            }

            float sunTexture(float2 uv)
            {
              return fbm(uv + fbm(5 * uv + _Time.x, _octaves), _octaves);
            }

            float4 nearSunTexture(float2 iuv)
            {
                float2 uv = iuv * 250;
                float2 i = floor(uv);
                float2 f = frac(uv);
                float3 col = (f).xyy;

                float minDist = 1.0;

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 n = float2(float(x), float(y));
                        float2 p = noise(i + n);
                        // p.y = 0.5 + 0.5 * sin(_Time + 5. * p.y);
                        // p.x = 0.5 + 0.5 * cos(_Time + 5. * p.x);
                        p = 0.5 + 0.5 * sin(_Time + 6.2831 * p);

                        float2 diff = n + p - f;
                        float dist = length(diff);
                        minDist = min(minDist, dist);

                    }
                }

                return minDist;
            }

            float remap(float value, float min1, float max1, float min2, float max2)
            {
                return (value - min1) * (max2 - min2) / (max1 - min1) + min2;
            }

            float sunTex(float2 uv)
            {
              float cellular = 1.0 / pow(nearSunTexture(uv) + 0.4, 3);
              float fbm = 3.0 * sunTexture(uv);

              float value = 0.0;

              if (_ZoomVal <= 0.2)
              {
                  float x = remap(_ZoomVal, 0.0, 0.2, 0.0, 1.0);
                  value = lerp(cellular, fbm, x);
              }
              else
              {
                  value = fbm;
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
              float3 position = v.vertex.xyz;
              float3 direction = normalize(position);

              // Calculate heightmap using FBM like in the fragment shader.
              // Based on the resulting FBM texture, vertices will be
              // displaced. Darker regions are nearer the center while
              // brighter regions are more far away from the center
              // (displacement).
              position -= direction * sunTex(v.uv) * _displacement;

              v2f o;
              o.vertex = UnityObjectToClipPos(float4(position, 1.0));
              o.uv = v.uv;

              return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float texColor = sunTex(i.uv);
                float4 color = lerp(_color1, _color2, texColor);
                return color;
            }
            
            ENDCG
        }
    }
}