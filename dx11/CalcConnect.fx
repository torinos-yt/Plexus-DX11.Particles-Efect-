struct Particle {
	#if defined(COMPOSITESTRUCT)
  		COMPOSITESTRUCT
 	#else
		float3 position;
	#endif
};

struct lineData{
	float3 Pos1;
	float3 Pos2;
	float4 p1Color;
	float4 p2Color;
	float alpha;
};

StructuredBuffer<Particle> ParticleBuffer;
StructuredBuffer<uint> AliveCounterBuffer;
StructuredBuffer<uint> AlivePointerBuffer;

float mindist<string uiname = "Min Distance"; float uimin = 0.0;> = 0.0;
float maxdist<string uiname = "Max Distance"; float uimin = 0.0;> = 1.0;

uint alphaMode<float uimin = 0.0;>;

AppendStructuredBuffer<lineData> output : BACKBUFFER;

[numthreads(32, 32, 1)]
void Calcline(uint3 dtid : SV_DispatchThreadID){
	uint count = AliveCounterBuffer[0];
	if(dtid.x >= count || dtid.y >= count) return;

	float3 p1 = ParticleBuffer[AlivePointerBuffer[dtid.x]].position;
	float3 p2 = ParticleBuffer[AlivePointerBuffer[dtid.y]].position;
	
	float4 p1col = float4(1,1,1,1);
	float4 p2col = float4(1,1,1,1);
	
	#if defined(KNOW_COLOR)
       p1col = ParticleBuffer[AlivePointerBuffer[dtid.x]].color;
	   p2col = ParticleBuffer[AlivePointerBuffer[dtid.y]].color;
    #endif
	
	float dist = distance(p1, p2);
	if(mindist < dist && dist < maxdist){
		lineData data;
		data.Pos1 = p1;
		data.Pos2 = p2;
		data.p1Color = p1col;
		data.p2Color = p2col;
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