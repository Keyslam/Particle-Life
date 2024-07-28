#pragma language glsl4

struct Count {
    uint value;
};

buffer Counts {
    Count counts[];
};

buffer CountReduce {
    Count countsReduce[];
};

buffer PrefixSum {
    Count prefixSum[];
};

buffer Offsets {
    Count offsets[];
};

uniform uint segments;

layout(local_size_x = 16, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint bit = love_GlobalThreadID.x;

    countsReduce[bit].value = 0;

    for (uint i = 0; i < segments; i++) {
        uint count = counts[i * 16 + love_GlobalThreadID.x].value;
        countsReduce[bit].value += count;
    }

    barrier();

    prefixSum[bit].value = bit == 0 ? 0 : countsReduce[bit - 1].value;
    barrier();
    for (uint n = 0; n < 4; n++) {
        uint offset = uint(pow(2, n));
        uint newPrefixSum = prefixSum[bit].value + prefixSum[bit - offset].value;
        barrier();
        prefixSum[bit].value = newPrefixSum;
    }

    barrier();

    offsets[bit].value = prefixSum[bit].value;
    for (uint n = 1; n < 40; n++) {
        offsets[n * 16 + bit].value = offsets[(n - 1) * 16 + bit].value + counts[(n - 1) * 16 + bit].value;
    }
}