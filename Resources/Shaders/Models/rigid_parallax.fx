float4 cColor = {1.0f, 1.0f, 1.0f, 1.0f};
float4x4 worldMatrix;
float4x4 viewProjMatrix;
float4x4 modelview;
float tile = 1;
float depth = 0.1;
float3 ambient = {0.2,0.2,0.2};
float3 diffuse = {1,1,1};
float3 specular = {0.75,0.75,0.75};
float shine = 128.0;
float3 lightpos = { -150.0, 200.0, -125.0 };
shared float fSaturate = 1.0;
float4x4 modelrotation;
float4x4 view;

texture texture0;
texture texture1;

sampler2D texmap_sampler = sampler_state
{
	Texture = <texture0>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D reliefmap_sampler = sampler_state
{
	Texture = <texture1>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};


//-----------------------------------------------------------------------------
// Vertex Definitions
//-----------------------------------------------------------------------------

struct VS_INPUT
{
	float3 Position : POSITION0;
	float3 Normal 	: NORMAL0;
	float2 TexCoord : TEXCOORD0;
	float3 Tangent 	: TANGENT0;
	float3 Binormal : BINORMAL0;
};

struct VS_OUTPUT 
{
    float4 hpos		: POSITION;
    float2 TexCoord 	: TEXCOORD0;
    float4 Color 	: COLOR0;
    float3 Position 	: TEXCOORD1;
    float3 tangent	: TEXCOORD2;
    float3 binormal	: TEXCOORD3;
    float3 normal	: TEXCOORD4;
    float4 lightpos	: TEXCOORD5;
};

struct PS_OUTPUT
{
	float4 color : COLOR;
};

//-----------------------------------------------------------------------------
// Vertex Shader
//-----------------------------------------------------------------------------
VS_OUTPUT VS( VS_INPUT IN )
{
/*
    VS_OUTPUT OUT;

    float4 newPos = mul(worldMatrix, float4(IN.Position,1.0));
    newPos = mul( viewProjMatrix, newPos);

	// compute modelview rotation only part
	float3x3 modelviewrot;
	modelviewrot[0] = modelview[0].xyz;
	modelviewrot[1] = modelview[1].xyz;
	modelviewrot[2] = modelview[2].xyz;

	// vertex position in view space (with model transformations)
	//float4 pos = float4(IN.Position.x, IN.Position.y, IN.Position.z, 1.0);
    OUT.hpos = mul(modelview, newPos);
    OUT.Position = OUT.hpos.xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	float3x3 mTangent;
        mTangent[0] = IN.Tangent;
        mTangent[1] = IN.Binormal;
        mTangent[2] = IN.Normal;
	float3x3 mTangent2 = mul(transpose((float3x3)worldMatrix), mTangent);
	float3x3 mTangentSpace2 = mul(modelviewrot, mTangent2);
	OUT.tangent	=	mTangentSpace2[0];
	OUT.binormal	=	mTangentSpace2[1];
	OUT.normal	=	mTangentSpace2[2];


    //OUT.txcoord = IN.tex0.xy;
    OUT.TexCoord = IN.TexCoord;
    OUT.Color = cColor;

    return OUT;
*/

    VS_OUTPUT OUT;

    float4 newPos = mul(worldMatrix, float4(IN.Position,1.0));
    newPos = mul( viewProjMatrix, newPos);

	// compute modelview rotation only part
	float3x3 modelviewrot;
	modelviewrot[0] = modelview[0].xyz;
	modelviewrot[1] = modelview[1].xyz;
	modelviewrot[2] = modelview[2].xyz;

	// vertex position in view space (with model transformations)
	//float4 pos = float4(IN.Position.x, IN.Position.y, IN.Position.z, 1.0);
    OUT.hpos = newPos; // mul(modelview, newPos);
    OUT.Position = OUT.hpos.xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	float3x3 mTangent;
        mTangent[0] = IN.Tangent;
        mTangent[1] = IN.Binormal;
        mTangent[2] = IN.Normal;
	float3x3 mTangent2 = mul(transpose((float3x3)worldMatrix), mTangent);
	float3x3 mTangentSpace2 = mul(modelviewrot, mTangent2);
	OUT.tangent	=	mTangentSpace2[0];
	OUT.binormal	=	mTangentSpace2[1];
	OUT.normal	=	mTangentSpace2[2];


    //OUT.txcoord = IN.tex0.xy;
    OUT.TexCoord = IN.TexCoord;
    OUT.Color = cColor;

    return OUT;

};

//-----------------------------------------------------------------------------
// Pixel Shader
//-----------------------------------------------------------------------------
PS_OUTPUT PS( VS_OUTPUT IN )
{
   	// view and light directions
	float3 v = normalize(IN.Position);
	float3 l = normalize(IN.lightpos.xyz - IN.Position);
	float2 uv = IN.TexCoord * tile;

	// parallax code
	/*
	float3x3 tbn = float3x3(IN.tangent, IN.binormal, IN.normal);
	float height = tex2D(reliefmap_sampler, uv).w * 0.06 - 0.03;
	uv += height * mul(v, tbn);
	*/

	// normal map
	float4 normal = tex2D(reliefmap_sampler, uv);
	normal.xy = normal.xy * 2.0 - 1.0; // transform to [-1,1] range
	normal.z = sqrt(1.0 - dot(normal.xy, normal.xy)); // compute z component

	// transform normal to world space
	normal.xyz = normalize(normal.x * IN.tangent - normal.y * IN.binormal + normal.z * IN.normal);

	// color map
	float4 color = tex2D(texmap_sampler, uv);

	// compute diffuse and specular terms
	float att = saturate(dot(l,IN.normal.xyz));
	float diff = saturate(dot(l,normal.xyz));
	float spec = saturate(dot(normalize(l-v),normal.xyz));

	// compute final color
	PS_OUTPUT OUT;
	OUT.color.xyz = (ambient*color.xyz)+att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine)) * fSaturate;
	OUT.color.w = 1.0;

	return OUT;
};

technique T0
{
	pass p0
	{
		ZEnable=true;
		ZWriteEnable=true;
		//AlphaBlendEnable=false;
		//AlphaTestEnable=false;
		//BlendMode=none;
		CullMode=CCW;
		//FillMode=wireframe;
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PS();
	}
}

technique FallbackOne
{
	pass p0
	{
		CullMode=CCW;
		VertexShader = compile vs_1_1 VS();
	}
}

technique FallbackTwo
{
	pass p0
	{
		CullMode=CCW;
	}
}

