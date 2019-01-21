Texture2D texture2d <string uiname="Texture";>;

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
 
cbuffer cbPerDraw : register( b0 )
{
	float4x4 tWVP : WORLDVIEWPROJECTION;
	float4x4 tVI : INVERSEVIEW;
	float4x4 tV : VIEW;
};

cbuffer cbPerObj : register( b1 )
{
	float4 linecol <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct lineData{
	float3 Pos1;
	float3 Pos2;
	float4 Col1;
	float4 Col2;
	float alpha;
};

struct vs2gs
{
    uint vid : TEXCOORD0;
};

struct gsout{
	float4 pos : SV_Position;
	float4 col : COLOR;
	float alpha : TEXCOORD0;
};

float3 MakeCamPos(float4x4 View){
	float tx = -dot(View[0], View[3]);
	float ty = -dot(View[1], View[3]);
	float tz = -dot(View[2], View[3]);
	return float3(tx, ty, tz);
}


StructuredBuffer<lineData> inputBuffer;
float width;

vs2gs VS(uint vid : SV_VertexID){
    vs2gs output;
	output.vid = vid;
    return output;
}

[maxvertexcount(2)]
void geomline (point vs2gs input[1], inout LineStream<gsout> outStream){
	gsout output0, output1;
	output0.pos = mul(float4(inputBuffer[input[0].vid].Pos1, 1), tWVP);
	output1.pos = mul(float4(inputBuffer[input[0].vid].Pos2, 1), tWVP);
	output0.col = inputBuffer[input[0].vid].Col1;
	output1.col = inputBuffer[input[0].vid].Col2;
	output0.alpha = inputBuffer[input[0].vid].alpha*1.5;
	output1.alpha = inputBuffer[input[0].vid].alpha*1.5;
	
	outStream.Append(output0);
	outStream.Append(output1);
	outStream.RestartStrip();
}

[maxvertexcount(4)]
void geompolyline (point vs2gs input[1], inout TriangleStream<gsout> outStream){
	gsout output0, output1, output2, output3;
	float3 campos = MakeCamPos(tV);
	
	float alpha = inputBuffer[input[0].vid].alpha;
	float wid = width * alpha / 300;
	
	float3 p1 = inputBuffer[input[0].vid].Pos1;
	float3 p2 = inputBuffer[input[0].vid].Pos2;
	
	float3 dir1 = normalize(campos - p1);
	float3 dir2 = normalize(campos - p2);
	float3 side = normalize(p1 - p2);
	float3 up1 = normalize(cross(dir1, side));
	float3 up2 = normalize(cross(dir2, side));
	
	output0.pos = mul(float4(p1 + up1 * (wid/2), 1), tWVP);
	output1.pos = mul(float4(p1 - up1 * (wid/2), 1), tWVP);
	output0.col = inputBuffer[input[0].vid].Col1;
	output1.col = inputBuffer[input[0].vid].Col1;
	output0.alpha = alpha;
	output1.alpha = alpha;
	
	output2.pos = mul(float4(p2 + up2 * (wid/2), 1), tWVP);
	output3.pos = mul(float4(p2 - up2 * (wid/2), 1), tWVP);
	output2.col = inputBuffer[input[0].vid].Col2;
	output3.col = inputBuffer[input[0].vid].Col2;
	output2.alpha = alpha;
	output3.alpha = alpha;
	
	outStream.Append(output0);
	outStream.Append(output1);
	outStream.Append(output2);
	outStream.Append(output3);
	outStream.RestartStrip();
}

float4 PS(gsout In): SV_Target{
    float4 col = linecol *In.col *  In.alpha;
    return col;
}

technique10 Line{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0,geomline() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

technique10 Polyline{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0,geompolyline() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




