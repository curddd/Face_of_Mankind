#include "..\Shared\objecttransforms.fx"
#include "..\Shared\vertexblending.fx"

float4 cColor = {1.0f, 1.0f, 1.0f, 1.0f};
int BoneCount = 0;
float tile = 1;
float depth = 0.1;
float3 ambient = {0.2,0.2,0.2};
float3 diffuse = {1,1,1};
float3 specular = {0.75,0.75,0.75};
float shine = 128.0;
float3 lightpos = { -150.0, 200.0, -125.0 };
shared float fSaturate = 1.0;
float4x4 modelrotation;

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
	float3 position			: POSITION;
	float3 BlendWeights 		: BLENDWEIGHT;
	float3 normal	 		: NORMAL;
	float2 tex0 			: TEXCOORD0;
	float3 tangent			: TANGENT0;
	float3 binormal			: BINORMAL0;

};

struct VERTEX_OUT
{
    float4 hpos		: POSITION;
    float4 color	: COLOR0;
    float2 txcoord	: TEXCOORD0;
    float3 vpos		: TEXCOORD1;
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

float3x3 GetTangentSpace(float3 vTangent, float3 vBinormal, float3 vNormal)
{
	float3x3 mResult;
	mResult[0] = vTangent;
	mResult[1] = vBinormal;
	mResult[2] = vNormal;
	return mResult;
}

float4 GetBlendedVert(float3 Position, float3 BlendWeights, int Bones)
{
		return Blend3Weights(Position, BlendWeights);
}

VERTEX_OUT VS_WEIGHTS( VS_INPUT IN )
{
	VERTEX_OUT OUT;
	float4 vBlend =	GetBlendedVert(IN.position, IN.BlendWeights, BoneCount);

	// Set this is the view projection...
	float4 blendedPos = vBlend;
	float4 finalPos = mul( viewProjMatrix, blendedPos);
	OUT.hpos = finalPos;

	OUT.color = float4( 1.0, 1.0, 1.0, 1.0 );
	OUT.txcoord = IN.tex0;

	// compute modelview rotation only part
	float3x3 modelviewrot;
	modelviewrot[0] = modelview[0].xyz;
	modelviewrot[1] = modelview[1].xyz;
	modelviewrot[2] = modelview[2].xyz;

	// vertex position in view space (with model transformations)
	float4 pos = float4(IN.position.x, IN.position.y, IN.position.z, 1.0);
	OUT.vpos = mul(modelview, blendedPos).xyz;

	// light position in view space
	float4 lp = float4(lightpos.x, lightpos.y, lightpos.z, 1);
	OUT.lightpos = mul(view, lp);

	float3x3 mTangent = GetTangentSpace(IN.tangent, IN.binormal, IN.normal);
	float3x3 mTangent2 = mul(transpose((float3x3)worldMatrix), mTangent);
	float3x3 mTangentSpace2 = mul(modelviewrot, mTangent2);
	OUT.tangent	=	mTangentSpace2[0];
	OUT.binormal	=	mTangentSpace2[1];
	OUT.normal	=	mTangentSpace2[2];
	
	// copy color and texture coordinates
	OUT.color = cColor;
	OUT.txcoord = IN.tex0.xy;

	return OUT;
}

//-----------------------------------------------------------------------------
// Pixel Shader
//-----------------------------------------------------------------------------

float4 parallax_map( VERTEX_OUT IN ) : COLOR
{
   	// view and light directions
	float3 v = normalize(IN.vpos);
	float3 l = normalize(IN.lightpos.xyz - IN.vpos);

	float2 uv = IN.txcoord * tile;

	
	// parallax code
	/*
	float3x3 tbn = float3x3(IN.tangent, IN.binormal, IN.normal);
	float height = tex2D(reliefmap_sampler, uv).w * 0.06 - 0.03;
	uv += height * mul(v, tbn);
	*/

	// normal map
	float4 normal = tex2D(reliefmap_sampler, uv);
	normal.xy = normal.xy * 2.0 - 1.0; // trafsform to [-1,1] range
	normal.z = sqrt(1.0 - dot(normal.xy, normal.xy)); // compute z component

	// transform normal to world space
	normal.xyz = normalize(normal.x * IN.tangent - normal.y * IN.binormal + normal.z * IN.normal);
	//normal.xyz = normalize(normal.xyz);

	// color map
	float4 color = tex2D(texmap_sampler, uv);

	// compute diffuse and specular terms
	float att = saturate(dot(l,IN.normal.xyz));
	float diff = saturate(dot(l,normal.xyz));
	float spec = saturate(dot(normalize(l-v),normal.xyz));

	// compute final color
	float4 finalcolor;// = normal;
	finalcolor.xyz = (ambient*color.xyz)+att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine)) * fSaturate;
	finalcolor.w = 1.0;

	return finalcolor;
}

//
technique T0
{
	pass p0
	{
		//ZEnable=false;
		//ZWriteEnable=true;
		//AlphaBlendEnable=false;
		//AlphaTestEnable=false;
		//BlendMode=none;
		CullMode=CCW;
		//FillMode=wireframe;
		VertexShader = compile vs_1_1 VS_WEIGHTS();
		PixelShader  = compile ps_2_0 parallax_map();
	}
}

technique Fallback
{
    pass p0
    {
    }
}
