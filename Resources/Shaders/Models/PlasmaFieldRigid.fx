
float tile = 1;
float3 ambient = {0.2,0.2,0.2};
float3 diffuse = {1,1,1};
float3 specular = {0.75,0.75,0.75};
float4 ForceFieldColor = {0.4, 0.5, 1.0, 0.5};
float4 fAuraColor = {1, 1, 1, 1};
float fAuraPow = 0.8;
float fRefractionIndex = 0.005;

float gTimer : TIME < string UIWidget = "None"; >;
float2 gAnimDir = {1, 0};
float gSpeed = 0.1;
float2 gAnimDir2 = {-1, 1};
float gSpeed2 = 0.07;
float2 gAnimDir3 = {0, -1};
float gSpeed3 = 0.05;
float2 gNormalAnimDir = {1, 1};
float gNormalSpeed = 0.05;

float shine = 128.0;
float3 lightpos = { -150.0, 200.0, -125.0 };

shared float fSaturate = 1.0;

float4x4 worldMatrix : WorldTranspose;
float4x4 viewProjMatrix : ViewProjectionTranspose;
//float4x4 modelviewproj : WorldViewProjectionTranspose;
float4x4 modelview : WorldViewTranspose;
float4x4 view : ViewTranspose;

texture texture0;
texture texture1;
texture backbuffer;

sampler2D texmap_sampler = sampler_state
{
	Texture = <texture0>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D normalmap_sampler = sampler_state
{
	Texture = <texture1>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D backbuffer_sampler = sampler_state
{
	Texture = <backbuffer>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

struct VERTEX_IN
{
	float3 Position 	: POSITION0;
	float3 Normal 	: NORMAL0;
	float2 TexCoord 	: TEXCOORD0;
	float3 Tangent 	: TANGENT0;
	float3 Binormal 	: BINORMAL0;
};

struct VERTEX_OUT
{
    float4 hpos		: POSITION;
    float2 txcoord	: TEXCOORD0;
    float3 vpos		: TEXCOORD1;
    float4 txcoord2	: TEXCOORD2;
    float3 normal	: TEXCOORD4;
    float4 lightpos	: TEXCOORD5;
};

// Get tex coords from our clip space transformed vertex position
float4 GetScreenTexCoords(float4 vPos)
{
	float4 vResult;
	vResult.x = ( vPos.x * 0.5 + vPos.w * 0.5 );
	vResult.y = ( vPos.w * 0.5 - vPos.y * 0.5 );
//	vResult.x = ( vPos.x * 0.5 + 0.5 );
//	vResult.y = ( 0.5 - vPos.y * 0.5 );
	vResult.z = vPos.w;
	vResult.w = vPos.w;
	return vResult;
}

VERTEX_OUT view_space(VERTEX_IN IN)
{
	VERTEX_OUT OUT;

	// vertex position in object space
	float4 pos = float4(IN.Position.x, IN.Position.y, IN.Position.z, 1.0);

	// compute modelview rotation only part
	
	float3x3 modelviewrot;
	modelviewrot[0] = modelview[0].xyz;
	modelviewrot[1] = modelview[1].xyz;
	modelviewrot[2] = modelview[2].xyz;

	float4 newPos = mul(worldMatrix, float4(IN.Position,1.0));
	newPos = mul( viewProjMatrix, newPos);
	OUT.hpos = newPos;
	
	// vertex position in view space (with model transformations)
	OUT.vpos = mul(modelview, pos).xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	// tangent space vectors in view space (with model transformations)
	OUT.normal	=	mul(modelviewrot, IN.Normal.xyz);

	// copy color and texture coordinates
	OUT.txcoord = IN.TexCoord.xy;
	OUT.txcoord2 = GetScreenTexCoords(newPos);

	return OUT;
}

VERTEX_OUT simple_view_space(VERTEX_IN IN)
{
	VERTEX_OUT OUT;

	// vertex position in object space
	float4 pos = float4(IN.Position.x, IN.Position.y, IN.Position.z, 1.0);

	// compute modelview rotation only part
	float3x3 modelviewrot;
	modelviewrot[0] = modelview[0].xyz;
	modelviewrot[1] = modelview[1].xyz;
	modelviewrot[2] = modelview[2].xyz;

	float4 newPos = mul(worldMatrix, float4(IN.Position,1.0));
	newPos = mul( viewProjMatrix, newPos);
	OUT.hpos = newPos;
	
	// vertex position in view space (with model transformations)
	OUT.vpos = mul(modelview, pos).xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	// tangent space vectors in view space (with model transformations)
	OUT.normal	=	mul(modelviewrot, IN.Normal.xyz);

	// copy color and texture coordinates
	OUT.txcoord = IN.TexCoord.xy;
	OUT.txcoord2 = GetScreenTexCoords(newPos);

	return OUT;
}

float4 simple_plasma_map( VERTEX_OUT IN ) : COLOR
{
	float4 refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w));
	return refr;
}

float4 plasma_map( VERTEX_OUT IN ) : COLOR
{
   	// view and light directions
	float3 v = normalize(IN.vpos);
	float3 l = normalize(IN.lightpos.xyz - IN.vpos);

	float4 normal = tex2D(normalmap_sampler, IN.txcoord + gNormalAnimDir * gTimer * gNormalSpeed);
	//normal.xy = normal.xy * 2.0 - 1.0; // transform to [-1,1] range
	//normal.z = sqrt(1.0 - dot(normal.xy, normal.xy)); // compute z component

	normal = (normal * 2) - 1;

	// transform normal to world space
	normal.xyz = normalize(normal.xyz);
	//normal.xyz = normalize(normal.x * IN.tangent - normal.y * IN.binormal + normal.z * IN.normal);

	
	
	float4 refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w) + (fRefractionIndex * normal.xy));
//	float4 refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w));

	float2 uv = IN.txcoord * tile + gAnimDir * gTimer * gSpeed;
	float2 uv2 = IN.txcoord * tile + gAnimDir2 * gTimer * gSpeed2;
	float2 uv3 = IN.txcoord * tile + gAnimDir3 * gTimer * gSpeed3;

	float4 lightNormal = float4(IN.normal, 1);
//	float4 lightNormal = normal;

	// color map
	float4 color = tex2D(texmap_sampler, uv);
	float4 color2 = tex2D(texmap_sampler, uv2);
	float4 color3 = tex2D(texmap_sampler, uv3);
	float fFactor = 1.0f / 3.0f;
	color.a = color.b;
	color = color * fFactor + color2 * fFactor + color3 * fFactor;
	color = ForceFieldColor * color;
	
	// apply aura
	//float fAura = abs(pow(dot(IN.normal, float3(0, 0, 1)), fAuraPow) * 1.0);
	//color = color * fAura + fAuraColor * (1.0f - fAura);

	// compute diffuse and specular terms
//	float att = saturate(dot(l,IN.normal.xyz));
//	float diff = saturate(dot(l,lightNormal.xyz));
//	float spec = saturate(dot(normalize(l-v),lightNormal.xyz));

	// compute final color
	float4 finalcolor;
//	finalcolor.xyz = (ambient*color.xyz)+att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine)) * fSaturate;
//	finalcolor.w = color.w;

	// alpha blending
	finalcolor.rgb = color.rgb * color.a + refr.rgb * (1 - color.a);
	finalcolor.w = color.w;

	//return refr;
	return finalcolor;
	//return color;
}

float4 fallback( VERTEX_OUT IN ) : COLOR
{
	float2 uv = IN.txcoord * tile + gAnimDir * gTimer * gSpeed;
	float2 uv2 = IN.txcoord * tile + gAnimDir2 * gTimer * gSpeed2;
	float2 uv3 = IN.txcoord * tile + gAnimDir3 * gTimer * gSpeed3;

	// color map
	float4 color = tex2D(texmap_sampler, uv);
	float4 color2 = tex2D(texmap_sampler, uv2);
	float4 color3 = tex2D(texmap_sampler, uv3);
	float fFactor = 1.0f / 3.0f;
	color.a = color.b;
	color = color * fFactor + color2 * fFactor + color3 * fFactor;
	color = ForceFieldColor * color;
	
	// compute final color
	float4 finalcolor;
	finalcolor.xyz = color.xyz;
	finalcolor.w = color.w;

	return finalcolor;
}

technique PlasmaForceField
{
    pass p0
    {
		ZEnable = true;
		ZWriteEnable = true;
		CullMode = ccw;
		AlphaBlendEnable = false;
		//SrcBlend = SRCALPHA;
		//DestBlend = INVSRCALPHA;
		//BlendOp = ADD;
		//SrcBlendAlpha = SRCALPHA;
		//DestBlendAlpha = INVSRCALPHA;
		//BlendOpAlpha = ADD;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_0 plasma_map();
    }
}

technique PlasmaForceField2
{
    pass p0
    {
		ZEnable = true;
		ZWriteEnable = true;
		CullMode = ccw;
		AlphaBlendEnable = false;
		VertexShader = compile vs_1_1 simple_view_space();
		PixelShader  = compile ps_2_0 simple_plasma_map();
    }
    pass p1
    {
		ZEnable = true;
		ZWriteEnable = true;
		CullMode = cw;
		AlphaBlendEnable = false;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		BlendOp = ADD;
		SrcBlendAlpha = SRCALPHA;
		DestBlendAlpha = INVSRCALPHA;
		BlendOpAlpha = ADD;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_0 plasma_map();
    }
}

technique Fallback
{
   pass p0
    {
		ZEnable = true;
		ZWriteEnable = true;
		CullMode = cw;
		AlphaBlendEnable = true;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		BlendOp = ADD;
		SrcBlendAlpha = SRCALPHA;
		DestBlendAlpha = INVSRCALPHA;
		BlendOpAlpha = ADD;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_0 fallback();
    }
    pass p1
    {
		ZEnable = true;
		ZWriteEnable = true;
		CullMode = ccw;
		AlphaBlendEnable = true;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		BlendOp = ADD;
		SrcBlendAlpha = SRCALPHA;
		DestBlendAlpha = INVSRCALPHA;
		BlendOpAlpha = ADD;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_0 fallback();
    }
}
