#pragma language glsl4

struct Particle {
    vec2 position;
    vec2 velocity;
    uint kind;
};

buffer Particles {
    Particle particles[];
};

uniform float dt;
uniform uint count;
uniform vec2 resolution;

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint index = love_GlobalThreadID.x;

    if (index >= count) {
        return;
    }

    particles[index].position += particles[index].velocity * dt;

    vec2 position = particles[index].position;
    if (position.x < 0.) particles[index].position.x += resolution.x;
    if (position.x > resolution.x) particles[index].position.x -= resolution.x;
    if (position.y < 0.) particles[index].position.y += resolution.y;
    if (position.y > resolution.y) particles[index].position.y -= resolution.y;
}