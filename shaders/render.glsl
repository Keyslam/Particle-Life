#pragma language glsl4

struct Particle {
    vec2 position;
    vec2 velocity;
    uint kind;
};
    
readonly buffer Particles {
    Particle particles[];
};
        
uniform uint count;

vec3 colorbytes(float r, float g, float b) {
    return vec3(r / 255., g / 255., b / 255.);
}

vec3 colors[] = {
    colorbytes(234, 89, 89),
    colorbytes(234, 168, 86),
    colorbytes(239, 215, 127),
    colorbytes(143, 217, 86),
    colorbytes(99, 216, 162),
    colorbytes(73, 142, 188),
    colorbytes(106, 85, 209),
    colorbytes(106, 85, 209),
    colorbytes(106, 85, 209),
    colorbytes(106, 85, 209),
    colorbytes(106, 85, 209)
};

#ifdef PIXEL
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec3 col = vec3(0.0);

        texture_coords.x = texture_coords.x * 1920f;
        texture_coords.y = texture_coords.y * 1080f;

        for (uint i; i < count; i++) {
            vec2 pos = particles[i].position;

            float distance = length(texture_coords - pos);
            float intensity = 1f / pow(distance, 1.3f); 

            col += colors[particles[i].kind] * intensity;
        }

        return vec4(pow(col, vec3(2.0)), 1.0);
    }
#endif