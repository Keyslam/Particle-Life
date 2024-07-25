struct Particle {
    vec2 position;
    vec2 velocity;
    uint kind;
};

buffer Particles {
    Particle particles[];
};

uniform float dt;
uniform float frictionFactor;
uniform uint count;
uniform vec2 resolution;

uniform float attractionmatrix[49];

float calculateforce(float r, float a) {
    float beta = 0.3f;

    if (r < beta) {
        return r / beta - 1.;
    } else if (beta < r && r < 1.) {
        return a * (1. - abs(2. * r - 1. - beta) / (1. - beta)); 
    } else {
        return 0.;
    }
}

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
void computemain() {
    uint index = love_GlobalThreadID.x;

    if (index >= count) {
        return;
    }

    vec2 force = vec2(0.0f, 0.0f);

    for (uint o_index = 0; o_index < count; o_index++) {
        Particle o_particle = particles[o_index];

        vec2 delta = o_particle.position - particles[index].position;
        delta.x = delta.x - resolution.x * floor(0.5 + delta.x / resolution.x);
        delta.y = delta.y - resolution.y * floor(0.5 + delta.y / resolution.y);

        float distance = sqrt(delta.x * delta.x + delta.y * delta.y);

        if (distance > 0. && distance < 200.) {
            float a = attractionmatrix[particles[index].kind + o_particle.kind * 3];
            float f = calculateforce(distance / 200., a);

            force += delta / distance * f;
        }
    }

    force *= 200. * 10.;

    particles[index].velocity *= frictionFactor;
    particles[index].velocity += force * dt;
}