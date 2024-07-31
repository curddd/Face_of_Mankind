
float tile = 0.1;
float3 ambient = {0.2,0.2,0.2};
float3 diffuse = {1,1,1};
float3 specular = {0.75,0.75,0.75};
float4 ForceFieldColor = {1, 1, 1.0, 0.7};
float fRefractionIndex = 0.02;

float gTimer : TIME < string UIWidget = "None"; >;
float2 gAnimDir = {1, 0};
float gSpeed = 0.05;
float2 gAnimDir2 = {-1, 1};
float gSpeed2 = 0.035;
float2 gAnimDir3 = {0, -1};
float gSpeed3 = 0.025;

float shine = 128.0;
float3 lightpos = { -150.0, 200.0, -125.0 };

float fSaturate = 1.0;

float4x4 worldMatrix : WorldTranspose;
float4x4 viewProjMatrix : ViewProjectionTranspose;
//float4x4 modelviewproj : WorldViewProjectionTranspose;
float4x4 modelview : WorldViewTranspose;
float4x4 view : ViewTranspose;
//float4x4 proj : ProjectionTranspose;

texture texture0;
texture texture1;
texture backbuffer;
//texture depthbuffer;
texture depthbuffer : RENDERDEPTHSTENCILTARGET;

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
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler2D depth_sampler = sampler_state
{
	Texture = <depthbuffer>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

struct VERTEX_IN 
{
	float3 Position : POSITION0;
	float3 Normal 	: NORMAL0;
	float3 Tangent 	: TANGENT0;
	float3 Binormal : BINORMAL0;
	float4 Color 	: COLOR0;
	float3 TexCoord : TEXCOORD0;
};

struct VERTEX_OUT
{
    float4 hpos		: POSITION;
    float4 color	: COLOR0;
    float2 txcoord	: TEXCOORD0;
    float3 vpos		: TEXCOORD1;
    float4 txcoord2	: TEXCOORD2;
    float4 projpos	: TEXCOORD3;
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
	OUT.projpos = newPos;
	
	// vertex position in view space (with model transformations)
	OUT.vpos = mul(modelview, pos).xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	// tangent space vectors in view space (with model transformations)
	OUT.normal	=	mul(modelviewrot, IN.Normal.xyz);

	// copy color and texture coordinates
	OUT.color = IN.Color;
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
	OUT.projpos = newPos;
	
	// vertex position in view space (with model transformations)
	OUT.vpos = mul(modelview, pos).xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	// tangent space vectors in view space (with model transformations)
	OUT.normal	=	mul(modelviewrot, IN.Normal.xyz);

	// copy color and texture coordinates
	OUT.color = IN.Color;
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
	float2 uv = IN.txcoord * tile + gAnimDir * gTimer * gSpeed;
	float2 uv2 = IN.txcoord * tile + gAnimDir2 * gTimer * gSpeed2;
	float2 uv3 = IN.txcoord * tile + gAnimDir3 * gTimer * gSpeed3;

	float4 normal1 = tex2D(normalmap_sampler, uv);
	normal1 = (normal1 * 2) - 1;
	normal1.xyz = normalize(normal1.xyz);

	float4 normal2 = tex2D(normalmap_sampler, uv2);
	normal2 = (normal2 * 2) - 1;
	normal2.xyz = normalize(normal2.xyz);

	float4 normal3 = tex2D(normalmap_sampler, uv3);
	normal3 = (normal3 * 2) - 1;
	normal3.xyz = normalize(normal3.xyz);

	float4 normal = normalize(normal1 + normal2 + normal3);

	float refDepth = tex2D(depth_sampler, (IN.txcoord2.xy / IN.txcoord2.w) + (fRefractionIndex * normal.xy));
	
	float4 refr;
	bool bCheckDepth = false;
	
	//test refraction target pixel depth
	if (bCheckDepth && (refDepth < IN.projpos.z / IN.projpos.w))
	{
		//don't refract pixels which refracted coords would lie in front of the rendered pixel
		refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w));
	}
	else
	{
		refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w) + (fRefractionIndex * normal.xy));
	};
	

	float4 lightNormal = normal;
//	float4 lightNormal = normal;

	// color map
	float4 color = tex2D(texmap_sampler, uv);
	float4 color2 = tex2D(texmap_sampler, uv2);
	float4 color3 = tex2D(texmap_sampler, uv3);
	float fFactor = 1.0f / 3.0f;
	color.a = color.b;
	color = color * fFactor + color2 * fFactor + color3 * fFactor;
	color = ForceFieldColor * color;
	
   	// view and light directions
	float3 v = normalize(IN.vpos);
	float3 l = normalize(IN.lightpos.xyz - IN.vpos);

	// compute diffuse and specular terms
	float att = saturate(dot(l,IN.normal.xyz));
	float diff = saturate(dot(l,lightNormal.xyz));
	float spec = saturate(dot(normalize(l-v),lightNormal.xyz));

	// compute final color
	float4 finalcolor;
	//finalcolor.xyz = color.xyz;
	finalcolor.xyz = (ambient*color.xyz)+att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine)) * fSaturate;
	finalcolor.w = color.w;

	// alpha blending
	finalcolor.rgb = finalcolor.rgb * finalcolor.a + refr.rgb * (1 - finalcolor.a);
	//finalcolor.rgb = finalcolor.rgb * finalcolor.a * refr.rgb * (1 - finalcolor.a);
	//finalcolor.a = 1;

	//return refr;
	return finalcolor;
	//return color;
	//return float4(IN.projpos.z, IN.projpos.z, IN.projpos.z, 1.0f);
	//return float4(IN.projpos.z /IN.projpos.w, IN.projpos.z /IN.projpos.w, IN.projpos.z /IN.projpos.w, 1.0f);
	//return tex2D(depth_sampler, IN.txcoord2.xy / IN.txcoord2.w);
}

float4 plasma_map2( VERTEX_OUT IN ) : COLOR
{
	float2 uv = IN.txcoord * tile + gAnimDir * gTimer * gSpeed;
	float2 uv2 = IN.txcoord * tile + gAnimDir2 * gTimer * gSpeed2;
	float2 uv3 = IN.txcoord * tile + gAnimDir3 * gTimer * gSpeed3;

	float4 normal1 = tex2D(normalmap_sampler, uv);
	normal1 = (normal1 * 2) - 1;
	normal1.xyz = normalize(normal1.xyz);

	float4 normal2 = tex2D(normalmap_sampler, uv2);
	normal2 = (normal2 * 2) - 1;
	normal2.xyz = normalize(normal2.xyz);

	float4 normal3 = tex2D(normalmap_sampler, uv3);
	normal3 = (normal3 * 2) - 1;
	normal3.xyz = normalize(normal3.xyz);

	float4 normal = normalize(normal1 + normal2 + normal3);

	float refDepth = tex2D(depth_sampler, (IN.txcoord2.xy / IN.txcoord2.w) + (fRefractionIndex * normal.xy));
	
	float4 refr;
	bool bCheckDepth = false;
	
	//test refraction target pixel depth
	if (bCheckDepth && (refDepth < IN.projpos.z / IN.projpos.w))
	{
		//don't refract pixels which refracted coords would lie in front of the rendered pixel
		refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w));
	}
	else
	{
		refr = tex2D(backbuffer_sampler, (IN.txcoord2.xy / IN.txcoord2.w) + (fRefractionIndex * normal.xy));
	};
	

	float4 lightNormal = normal;
//	float4 lightNormal = normal;

	// color map
	float4 color = tex2D(texmap_sampler, uv);
	float4 color2 = tex2D(texmap_sampler, uv2);
	float4 color3 = tex2D(texmap_sampler, uv3);
	float fFactor = 1.0f / 3.0f;
	color.a = color.b;
	color = color * fFactor + color2 * fFactor + color3 * fFactor;
	color = ForceFieldColor * color;
	
   	// view and light directions
	float3 v = normalize(IN.vpos);
	float3 l = normalize(IN.lightpos.xyz - IN.vpos);

	// compute diffuse and specular terms
	float att = saturate(dot(l,IN.normal.xyz));
	float diff = saturate(dot(l,lightNormal.xyz));
	float spec = saturate(dot(normalize(l-v),lightNormal.xyz));

	// compute final color
	float4 finalcolor;
	//finalcolor.xyz = color.xyz;
	finalcolor.xyz = (ambient*color.xyz)+att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine)) * fSaturate;
	finalcolor.w = color.w;

	// alpha blending
	finalcolor.rgb = finalcolor.rgb * finalcolor.a + refr.rgb * (1 - finalcolor.a);
	//finalcolor.rgb = finalcolor.rgb * finalcolor.a * refr.rgb * (1 - finalcolor.a);
	//finalcolor.a = 1;

	//return refr;
	return finalcolor;
	//return color;
	//return float4(IN.projpos.z, IN.projpos.z, IN.projpos.z, 1.0f);
	//return float4(IN.projpos.z /IN.projpos.w, IN.projpos.z /IN.projpos.w, IN.projpos.z /IN.projpos.w, 1.0f);
	//return tex2D(depth_sampler, IN.txcoord2.xy / IN.txcoord2.w);
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

technique PlasmaForceField2
{
    pass p0
    {
		ZEnable = true;
		ZWriteEnable = true;
		CullMode = cw;
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
		PixelShader  = compile ps_2_0 plasma_map2();
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
