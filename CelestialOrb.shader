Shader "Custom/CelestialOrb"
{
    Properties
    {
        [HDR]_BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _Texture1("Texture 1", 2D) = "white"{}
        _Texture1PanSpeed("Texture 1 Pan Speed", float) = 1
        _Texture1RotationSpeed("Texture 1 Rotation Speed", float) = 1
        _Texture2("Texture 2", 2D) = "white"{}
        _Texture2PanSpeed("Texture 2 Pan Speed", float) = 1
        _Texture2RotationSpeed("Texture 2 Rotation Speed", float) = 1
        _MaskRadius("Mask Radius", Range(0,1)) = 0.5
        _MaskSoftness("Mask Softness", Range(0,2)) = 0.05
        _MaskWobbleFrequency("Mask Wobble Frequency", Range(0,5)) = 1
        _MaskWobbleAmplitude("Mask Wobble Amplitude", Range(0,0.5)) = 0.03
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
                float2 uv : TEXCOORD0;
                float2 centeredUV : TEXCOORD1;
            };

            TEXTURE2D(_Texture1);
            SAMPLER(sampler_Texture1);
            TEXTURE2D(_Texture2);
            SAMPLER(sampler_Texture2);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float4 _Texture1_ST;
                float _Texture1PanSpeed;
                float _Texture1RotationSpeed;
                float4 _Texture2_ST;
                float _Texture2PanSpeed;
                float _Texture2RotationSpeed;
                float _MaskRadius;
                float _MaskSoftness;
                float _MaskWobbleFrequency;
                float _MaskWobbleAmplitude;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.centeredUV = IN.uv - 0.5;
                return OUT;
            }

            float2 PolarUV(float2 centeredUV, float4 ST, float panSpeed, float rotationSpeed)
            {
                float r = length(centeredUV);
                float angle = atan2(centeredUV.y, centeredUV.x);

                angle += _Time.y * rotationSpeed;

                float2 polarUV;

                polarUV.x = cos(angle) * ST.x;
                polarUV.y = r * ST.y - (_Time.y * panSpeed);

                polarUV += ST.zw;

                return polarUV;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv1 = PolarUV(IN.centeredUV, _Texture1_ST,_Texture1PanSpeed,_Texture1RotationSpeed);
                float2 uv2 = PolarUV(IN.centeredUV, _Texture2_ST,_Texture2PanSpeed,_Texture2RotationSpeed);

                half4 tex1 = SAMPLE_TEXTURE2D(_Texture1, sampler_Texture1, uv1);
                half4 tex2 = SAMPLE_TEXTURE2D(_Texture2, sampler_Texture2, uv2);

                half4 color = (tex1 + tex2) * _BaseColor;

                float radius = length(IN.centeredUV)+ (sin(_Time.y*_MaskWobbleFrequency)*_MaskWobbleAmplitude);
                float alphaMask = 1.0 - smoothstep(_MaskRadius - _MaskSoftness, _MaskRadius, radius);

                color.a = alphaMask;

                return color;
            }
            ENDHLSL
        }
    }
}
