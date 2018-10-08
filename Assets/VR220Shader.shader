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
			
			float linear_cos(float x) {
				const float PI = 3.141592;
				if (x <= PI) {
					return 1-x*2/PI;
				}
				else {
					return x*2/PI - 3;
				}					
			}

			float2 spherical2plane (float2 v) {
				const float PI = 3.141592;
				float theta = v.x;
				float phi = v.y;

				float x = sin(theta) * cos(phi);
				float y = cos(theta);

				// cosを直線に置き換えるとそれっぽく見える
				// float x = sin(theta) * (1-phi*2/PI);
				// float y = (1-theta*2/PI);
				// float x = sin(theta) * linear_cos(phi);
				// float x = sin(theta) * linear_cos(phi);
				// float y = linear_cos(theta);

				return float2(x,y);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// 画像の縦幅に対する魚眼画像の半径の比率
				const float img_h_to_r = 0.5;

				// 半径1の球面上の像を射影したときの魚眼画像の半径 (180度ならば1)
				const float fisheye_radius = 1.06;

				const float H = fisheye_radius / img_h_to_r;
				const float W = H * 4 / 3;

				// 前面
				if (i.uv.x <= 0.5 ) {
					// 前面だけを考慮するため、[0,1]へマップする
					const float PI = 3.141592;
					const float u = i.uv.x * 2;
					const float v = i.uv.y;

					float phi = u * PI;
					float theta = v * PI;

					// 球面上からのマッピング
					float2 xy = spherical2plane(float2(theta, phi));
					float x = xy.x;
					float y = xy.y;

					float r = sqrt(x*x+y*y);
					float2 n = xy / r;
					float psi = acos(r);
					xy = n * abs(1-2/PI*psi);
					x = xy.x;
					y = xy.y * (-1);

					float u_img = (x/W*2+1)/2;
					float v_img = (y/H*2+1)/2;

					float2 coord = float2(u_img, v_img);

					fixed4 col = tex2D(_MainTex, coord);
					return col;
				}
				// 背面
				else {
					// だけを考慮するため、[0,1]へマップする
					const float u = (i.uv.x - 0.5) * 2;
					const float v = i.uv.y;

					const float PI = 3.141592;
					float phi = u * PI;
					float theta = v * PI;
					
					float2 xy = spherical2plane(float2(theta, phi));
					xy.x *= -1;
					xy.y *= -1;
					float x = xy.x;
					float y = xy.y;
					float r = sqrt(x*x+y*y);
					float2 n = xy / r;
					float psi = acos(r);
					xy = n * (1+psi*2/PI);
					x = xy.x;
					y = xy.y;
					if (x*x+y*y >= fisheye_radius*fisheye_radius)
						return fixed4(0,0,0,1);

					float u_img = (x/W*2+1)/2;
					float v_img = (y/H*2+1)/2;

					float2 coord = float2(u_img, v_img);

					fixed4 col = tex2D(_MainTex, coord);
					return col;
				}
			}
			ENDCG
		}
	}
}
