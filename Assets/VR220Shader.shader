Shader "Unlit/VR220Shader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Cull Front
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
				// 定数の定義
				const float img_h_to_r = 0.5; 		// 画像の縦幅に対する魚眼画像の半径の比率
				const float fisheye_radius = 1.06;	// 半径1の球面上の像を射影したときの魚眼画像の半径 (180度ならば1)
				const float PI = 3.141592;			// 円周率
				const float H = fisheye_radius / img_h_to_r;	// 画像横幅
				const float W = H * 4 / 3;						// 画像縦幅

				bool is_front = i.uv.x >= 0.5;		// 前面 or 背面

				// 前面・背面をそれぞれ[0,1]x[0,1]へマップ
				float u = is_front ? i.uv.x*2 : (1-i.uv.x)*2;
				float v = i.uv.y;

				// 正距円筒図法の座標系
				float phi = u * PI;
				float theta = v * PI;

				// 球面上から平面（画像）への射影
				float2 p = float2(sin(theta) * cos(phi), cos(theta) * (-1));

				// 左右反転
				p.x *= -1;

				// そのままだと画像が歪むので補正
				// 平面（画像）上の極座標で見たときの長さを調整する
				float2 n = normalize(p);
				float r = length(p);
				float psi = acos(r);
				float r2 = is_front ? abs(1-2/PI*psi) : abs(1+2/PI*psi);
				float2 p2 = n * r2;

				// 範囲外にある部分は黒塗り
				if (!is_front && length(p2) >= fisheye_radius)
					return fixed4(0,0,0,1);

				// 画像のuv座標への変換とテクスチャの取得
				float2 coord = float2(p2.x/W+0.5, p2.y/H+0.5);
				fixed4 col = tex2D(_MainTex, coord);
				return col;
			}
			ENDCG
		}
	}
}
