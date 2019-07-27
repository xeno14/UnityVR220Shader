Shader "Unlit/VR220Shader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Front	// 法線の反転
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

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

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// 【仮定】
				// - 射影方式は正射影
				// - 魚眼画像は中心(0, 0)、半径1の円であるとする
				// - 魚眼画像は180度でちょうど画像の上下端に円が接している

				// 定数の定義
				const float PI = 3.141592;			// 円周率
				const float AR = 4.0 / 3.0;			// 画像アスペクト比
				const float H = 2;					// 画像縦幅
				const float W = H * AR;				// 画像縦幅

				bool is_front = i.uv.x >= 0.5;		// 前面 or 背面
				
				// 前面以外は黒塗り
				if (!is_front)
					return fixed4(0,0,0,1);

				// 前面を[0,1]x[0,1]へマップ
				float u = 2*i.uv.x - 1;
				float v = i.uv.y;

				// 左右反転（法線を反転したので）
				u = 1 - u;

				// 正距円筒図法の座標系
				float phi = -PI/2 + u * PI;
				float theta = v * PI;

				// 正射影
				float x = abs(sin(theta)) / sqrt(1 + pow(tan(phi), -2)) * sign(phi);
				float y = -cos(theta);
				float2 p = float2(x, y);

				// 画像のuv座標への変換とテクスチャの取得
				float2 p_img = float2(p.x/W+0.5, p.y/H+0.5);
				fixed4 col = tex2D(_MainTex, p_img);
				return col;
			}
			ENDCG
		}
	}
}
