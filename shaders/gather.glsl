#pragma language glsl4

struct ParticleCell {
    uint particleId;
    uint cellId; 
};

struct Count {
    uint value;
};

buffer ParticleCells {
    ParticleCell particleCells[];
};

buffer ParticleCellsOut {
    ParticleCell particleCellsOut[];
};

buffer Offsets {
    Count offsets[];
};

uniform uint count;
uniform uint segmentSize;

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint start = love_GlobalThreadID.x * segmentSize;
    uint end = min(count, love_GlobalThreadID.x * segmentSize + segmentSize);

    uint localOffsets[16];
    for (uint n = 0; n < 16; n++) {
        localOffsets[n] = offsets[love_GlobalThreadID.x * 16 + n].value;
    }

    for (uint index = start; index < end; index++) {
        uint cellId = particleCells[index].cellId;
        uint mask = cellId & 0xF; 

        uint i = localOffsets[mask];
        localOffsets[mask]++;

        particleCellsOut[i] = particleCells[index];
    }
}