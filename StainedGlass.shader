Shader "Custom/StainedGlass"
{
    Properties
    {
        [HDR]_Color1 ("Color A", Color) = (1,0.4,1,1)
        [HDR]_Color2 ("Color B", Color) = (0.3,0.6,1,1)
        [HDR]_Color3 ("Color C", Color) = (1,0.8,0.3,1)
        [HDR]_Color4 ("Color D", Color) = (0.2,1,0.9,1)
        _SquareSize("Square Size", Range (0,0.5)) = 0.2
        _GridSize ("Grid Size", Float) = 10
        _PulseSpeed("Pulse Speed", Float) = 2
        _PulseAmount("Pulse Amount", Float) = 0.1
        _RippleAmount("Ripple Amount", Float) = 0.5
        _WarpStrength("Warp Strength", Float) = 0.6
        _ColorSpeed ("Color Speed", Float) = 1
        _NoiseAmount ("Noise Amount", Float) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 centeredUv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _Color1;
                half4 _Color2;
                half4 _Color3;
                half4 _Color4;
                float _SquareSize;
                float _GridSize;
                float _PulseSpeed;
                float _PulseAmount;
                float _RippleAmount;
                float _WarpStrength;
                float _ColorSpeed;
                float _NoiseAmount;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.centeredUv = IN.uv-0.5;
                return OUT;
            }

            float hash21(float2 p){
                p = frac(p *float2(123.34,456.21));
                p += dot(p, p + 34.45);
                return frac(p.x * p.y);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float r = length(IN.centeredUv);
                float2 dir = normalize(IN.centeredUv);
                float warpedR = pow(r, _WarpStrength);
                
                float2 gridCenter = float2(_GridSize, _GridSize) * 0.5;
                float2 warpedUV = dir*warpedR;
                float2 gridUV = warpedUV * _GridSize;
                
                float2 cellID = floor(gridUV);
                float2 cellUV = frac(gridUV);
                float2 cellCenter = cellUV - 0.5;
                float cellNoise = hash21(cellID);
                
                float radialDistance = length(cellID + 0.5);
                float noisePhase = cellNoise * _NoiseAmount;
                float radialPhase = -radialDistance * _RippleAmount + noisePhase;

                
                float pulse = sin(_Time.y * _PulseSpeed + radialPhase);
                float animatedSize = _SquareSize + pulse *_PulseAmount;
                
                float squareSDF = max(abs(cellCenter.x), abs(cellCenter.y)) - animatedSize;
                float softenedSquare = smoothstep (0.01, 0.0, squareSDF);
                
                float gradientT = frac(_Time.y * _ColorSpeed - radialDistance * _RippleAmount + noisePhase);

                //Calculate our t values for a 3 color gradient
                float t1 = saturate(gradientT / 0.33);
                float t2 = saturate((gradientT - 0.33) / 0.33);
                float t3 = saturate((gradientT - 0.66) / 0.34);

                //Chain the values with lerps alone
                half4 gradient1 = lerp(_Color1, _Color2, t1);
                half4 gradient2 = lerp(_Color2, _Color3, t2);
                half4 gradient3 = lerp(_Color3, _Color4, t3);

                // Blend them all together with steps and lerps
                half4 color = lerp(gradient1, gradient2, step(0.33, gradientT));
                color = lerp(color, gradient3, step(0.66, gradientT));

                return color * softenedSquare;
            }
            ENDHLSL
        }
    }
}
