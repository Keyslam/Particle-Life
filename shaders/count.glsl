#pragma language glsl4

struct ParticleCell {
    uint particleId;
    uint cellId; 
};

buffer ParticleCells {
    ParticleCell particleCells[];
};

struct Count {
    uint value;
};

buffer Counts {
    Count counts[];
};

uniform uint count;
uniform uint segmentSize;

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint start = love_GlobalThreadID.x * segmentSize;
    uint end = min(count, love_GlobalThreadID.x * segmentSize + segmentSize);

    for (uint i = 0; i < 16; i++) {
        counts[love_GlobalThreadID.x * 16 + i].value = 0;
    }

    for (uint index = start; index < end; index++) {
        uint cellId = particleCells[index].cellId;
        uint mask = cellId & 0xF; 
        counts[love_GlobalThreadID.x * 16 + mask].value++;
    }
}