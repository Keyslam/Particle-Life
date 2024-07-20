extern float width = 1080.0f;
extern float blurAmount = 3.0f;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
    vec4 sum = vec4(0.0);
    vec2 tc = texture_coords;
    float hstep = blurAmount / width;

    sum += texture2D(texture, vec2(tc.x - 4.0 * hstep, tc.y)) * 0.05;
    sum += texture2D(texture, vec2(tc.x - 3.0 * hstep, tc.y)) * 0.09;
    sum += texture2D(texture, vec2(tc.x - 2.0 * hstep, tc.y)) * 0.12;
    sum += texture2D(texture, vec2(tc.x - 1.0 * hstep, tc.y)) * 0.15;
    sum += texture2D(texture, vec2(tc.x + 0.0 * hstep, tc.y)) * 0.16;
    sum += texture2D(texture, vec2(tc.x + 1.0 * hstep, tc.y)) * 0.15;
    sum += texture2D(texture, vec2(tc.x + 2.0 * hstep, tc.y)) * 0.12;
    sum += texture2D(texture, vec2(tc.x + 3.0 * hstep, tc.y)) * 0.09;
    sum += texture2D(texture, vec2(tc.x + 4.0 * hstep, tc.y)) * 0.05;

    return sum * color;
}