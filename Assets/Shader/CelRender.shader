Shader "Unlit/CelRender"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white" {}
        _RampTex("RmpTex",2D) = "white" {}
        _IlmTex("_IlmTex",2D) = "white" {}

         [Space(20)]
        _MainColor("Main Color",Color) = (1,1,1)
        _ShadowColor("Shadow Color", Color) = (0.7,0.7,0.8)
        _ShadowSmooth("Shadow Smmooth", Range(0,0.3)) = 0.002
        _ShadowRange ("Shadow Range", Range(0, 1)) = 0.5

         [Space(20)]
         _SpecularColor("Specular Color", Color) = (1,1,1)
         _SpecularRange("Specular Range", Range(0,1)) = 0.9
         _SpecularMulti("Specular Multi", Range(0,1)) = 0.4
         _SpecularGloss("Sprecular Gloss", Range(0.001, 8)) = 4

         [Space(20)]
         _RimColor("Rim Color",Color) = (1,1,1)
         _RimMin ("Rim Min", Range(0,1)) = 0.2
         _RimMax ("Rim Max", Range(0,1)) = 0.5
         _RimSmooth("_RimSmooth", Range(0,1)) = 0.5
         _RimPower("_RimPower", Range(0,5)) = 0
         _RimInstensity("_RimInstensity", Range(0,10)) = 0

         [Space(20)]
         _RimBloomPower("_RimBloomPower", Range(0,5)) = 4
         _RimBloomInstensity("_RimBloomInstensity", Range(0,10)) = 10

        [Space(20)]
        _Outlinewidth("Outline Width", Range(0, 1)) = 0.24
        _OutLineColor("OutLine Color", Color) = (0.5,0.5,0.5,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {   Tags{"LightMode" = "ForwardBase"}

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            sampler2D _RampTex;
            sampler2D _IlmTex;
            float4 _MainTex_ST;
            float4 _IlmTex_ST;

            half3 _MainColor;
            half4 _RimColor;
            half3 _ShadowColor;
            half _ShadowRange;
            half _ShadowSmooth;

            half3 _SpecularColor;
			half _SpecularRange;
        	half _SpecularMulti;
			half _SpecularGloss;

            half _RimMin ;
            half _RimMax ;
            half _RimSmooth;
            half _RimPower;
            half _RimInstensity;

            half _RimBloomPower;
            half _RimBloomInstensity;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXC00RD2;
            };

            v2f vert(a2v v){
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_TARGET
            {
                half4 col = 0;

                half4 mainTex = tex2D(_MainTex, i.uv);
                half4 ilmTex = tex2D(_IlmTex, i.uv);
                half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                half3 worldNormal = normalize(i.worldNormal);

                //diffuse
                half3 diffuse = 0;
                half halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5; //acculate halfLambert
                half threshold = (halfLambert + ilmTex.g) * 0.5;//use the lightmap`s g channel to acculate the threshold of color change (light or shadow)
                half ramp = saturate(_ShadowRange - threshold);//acculate the ramp of color
                ramp = smoothstep(0, _ShadowSmooth, ramp);//smooth the ramp
                diffuse = lerp(_MainColor,_ShadowColor, ramp);//use the ramp value to lerp color. add the shadow
                diffuse *=  mainTex.rgb;

                //specular
                half3 specular = 0;
                half3 halfDir = normalize(worldLight + viewDir);
                half Ndh = max(0,dot(worldNormal, halfDir));
                half SpecularSize = pow(Ndh, _SpecularGloss);
                half specularMask = ilmTex.b;//get the pecular mask from lightmap`s b channel
                if( SpecularSize >= 1 - specularMask * _SpecularRange){//judge this point whether the specular
                    specular = _SpecularMulti * (ilmTex.r) * _SpecularColor;// calculate specular color 
                }

                //rimcolor
                half f = 1.0 - max(0,(dot(worldNormal,viewDir)));//when the angle viewdir and normal is closer to 90бу,the rimcolor more strong.
                half rimVal = smoothstep(_RimMin, _RimMax, f);//set the range of rimcolor
                rimVal = smoothstep(0, _RimSmooth, rimVal);//set the softness
                rimVal = pow(rimVal,_RimPower)* _RimInstensity;//calculate the instensity of rimcolor
                half3 rimColor = rimVal * _RimColor.rgb;

                col.rgb =  _LightColor0.rgb * (rimColor + diffuse  + specular);
                col.a = pow(f,_RimBloomPower) * max(0, dot(worldNormal, worldLight)) * _RimBloomInstensity;//the alpha value is used when bloom, the point that have rimcolor and get light will have the bloom
                return col;
            }
            ENDCG
        }
        pass //Draw Outline
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            half _Outlinewidth;
            half4 _OutLineColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float uv : TEXCOORD0;
                float4 vertColor : COLOR;
                float tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 vertColor : TEXCOORD0;
            };

            v2f vert (a2v v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                float4 pos =  UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                float3 ndcNormal = normalize(TransformViewToProjection(viewNormal.xyz))*pos.w; //use the ndcnormal to prevention the change of the width of outline, when the camera chaned
                float4 projectionSpaceUpperRight = float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y);
                float4 nearUpperRight = mul(unity_CameraInvProjection, projectionSpaceUpperRight);
                float aspect = abs(nearUpperRight.y/nearUpperRight.x);//calculate height/width of screen
                ndcNormal.xy*=aspect;//correct the ndcnormal. [0,1] -> [width,height]
                pos.xy += ndcNormal.xy * _Outlinewidth * 0.01 ;
                o.pos = pos;
                o.vertColor = v.vertColor.rgb;
                return o;
                
            }
            
            half4 frag(v2f i) : SV_TARGET{
                return fixed4(_OutLineColor*i.vertColor,0);
            } 

        ENDCG

         
        }
        }
           
    }

