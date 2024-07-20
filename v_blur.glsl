extern float height = 1080.0f;
extern float blurAmount = 3.0f;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
    vec4 sum = vec4(0.0);
    vec2 tc = texture_coords;
    float vstep = blurAmount / height;

    sum += texture2D(texture, vec2(tc.x, tc.y - 4.0 * vstep)) * 0.05;
    sum += texture2D(texture, vec2(tc.x, tc.y - 3.0 * vstep)) * 0.09;
    sum += texture2D(texture, vec2(tc.x, tc.y - 2.0 * vstep)) * 0.12;
    sum += texture2D(texture, vec2(tc.x, tc.y - 1.0 * vstep)) * 0.15;
    sum += texture2D(texture, vec2(tc.x, tc.y + 0.0 * vstep)) * 0.16;
    sum += texture2D(texture, vec2(tc.x, tc.y + 1.0 * vstep)) * 0.15;
    sum += texture2D(texture, vec2(tc.x, tc.y + 2.0 * vstep)) * 0.12;
    sum += texture2D(texture, vec2(tc.x, tc.y + 3.0 * vstep)) * 0.09;
    sum += texture2D(texture, vec2(tc.x, tc.y + 4.0 * vstep)) * 0.05;

    return sum * color;
}