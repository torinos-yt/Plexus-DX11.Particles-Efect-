struct lineData{
	float3 Pos1;
	float3 Pos2;
	float4 Col1;
	float4 Col2;
	float alpha;
};

StructuredBuffer<float3> PositionBuffer;
StructuredBuffer<float4> ColorBuffer;

float mindist<string uiname = "Min Distance"; float uimin = 0.0;> = 0.0;
float maxdist<string uiname = "Max Distance"; float uimin = 0.0;> = 1.0;

uint alphaMode<float uimin = 0.0;>;

AppendStructuredBuffer<lineData> output : BACKBUFFER;

[numthreads(32, 32, 1)]
void Calcline(uint3 dtid : SV_DispatchThreadID){
	uint count, stride;
	uint cc;
	PositionBuffer.GetDimensions(count, stride);
	ColorBuffer.GetDimensions(cc, stride);
	if(dtid.x >= count || dtid.y >= count) return;

	float3 p1 = PositionBuffer[dtid.x];
	float3 p2 = PositionBuffer[dtid.y];
	float4 p1col = float4(1,1,1,1);
	float4 p2col = float4(1,1,1,1);
	
	#if USECOLOR == 1
		p1col = ColorBuffer[dtid.x % cc];
		p2col = ColorBuffer[dtid.y % cc];
	#endif

	float dist = distance(p1, p2);
	if(mindist < dist && dist < maxdist){
		lineData data;
		data.Pos1 = p1;
		data.Pos2 = p2;
		data.Col1 = p1col;
		data.Col2 = p2col;
		if(alphaMode == 0){
			data.alpha = 1;	
		}else if(alphaMode == 1){
			data.alpha = 1 - ((dist-mindist) / (maxdist-mindist));
		}else if(alphaMode == 2){
			data.alpha = 1 - (dist / maxdist);
		}else{
			data.alpha = ((dist-mindist) / (maxdist-mindist));
		}
		output.Append(data);
	}
}

technique11 CalcConectlLine { 
	pass P0{
		SetComputeShader( CompileShader( cs_5_0, Calcline() ) );
	}
}