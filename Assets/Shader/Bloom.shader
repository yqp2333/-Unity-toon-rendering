Shader "Unlit/Bloom"
{
    Properties
    {
        _MainTex ("BaseColor", 2D) = "white" {}
    }
    SubShader
    {
        ZTest Always  
        Cull Off  
        ZWrite Off  

        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _BlurTex;
        half4 _MainTex_TexelSize;
        fixed4 _BloomColor;
        float _LuminanceThreahold;
        float4 _offsets;
        float _BloomIntence;


//-------------------------------------------------------------------------
        struct v2fExtractBright{
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };


        v2fExtractBright vertExtractBright (appdata_img v)
        {
            v2fExtractBright o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        fixed luminance(fixed4 color) {
            return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
        }

        fixed4 fragExtractBright (v2fExtractBright i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);
            fixed val  = col.a;//clamp(luminance(col) -_LuminanceThreahold , 0.0, 1.0);
            return col * val;
        }
//--------------------------------------------------------------------------------------------------
        struct v2fBlur{
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 uv01 : TEXCOORD1;
            float4 uv23 : TEXCOORD2;
        };

        v2fBlur vertBlur(appdata_img v){
            v2fBlur o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord.xy;

            _offsets *= _MainTex_TexelSize.xyxy;  
            o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);  
            o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;  
            return o;  
        }

        fixed4 fragBlur(v2fBlur i) : SV_Target  
        {  
            fixed4 color = fixed4(0,0,0,0);  
            color += 0.4026 * tex2D(_MainTex, i.uv);  
            color += 0.2442 * tex2D(_MainTex, i.uv01.xy);  
            color += 0.2442 * tex2D(_MainTex, i.uv01.zw);  
            color += 0.0545 * tex2D(_MainTex, i.uv23.xy);  
            color += 0.0545 * tex2D(_MainTex, i.uv23.zw);  
            return color;  
        }

//--------------------------------------------------------------------------------------------------
        struct v2fBloom{
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        v2fBloom vertBloom(appdata_img v){
            v2fBloom o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;   
        return o;
        }
            

        fixed4 fragBloom(v2fBloom i): SV_Target{

            fixed4 mainColor = tex2D(_MainTex, i.uv);
            fixed4 blurColor = tex2D(_BlurTex, i.uv);

            fixed4 finalColor = mainColor + blurColor * _BloomColor * _BloomIntence;
            return finalColor;
        }
//-------------------------------------------------------------------------------------------------
        ENDCG

        // 亮度提取
        Pass {  
            CGPROGRAM  
            #pragma vertex vertExtractBright  
            #pragma fragment fragExtractBright  
            ENDCG  
        }

        //高斯模糊
        Pass {
            CGPROGRAM
            #pragma vertex vertBlur  
            #pragma fragment fragBlur
            ENDCG  
        }

        // Bloom
        Pass {
            CGPROGRAM
            #pragma vertex vertBloom  
            #pragma fragment fragBloom
            ENDCG  
        }
    }
}
