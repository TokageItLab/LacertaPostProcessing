/**
 * Lacerta Post Processing
 * LC Chromatic Aberration
 * Version 1.0.0.1
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform bool radial = true;

uniform float chromatic_aberration_scale: hint_range(0.0, 0.25) = 0.025;
uniform float chromatic_aberration_power: hint_range(1.0, 5.0) = 2.0;
uniform float chromatic_aberration_bias: hint_range(0.0, 1.0) = 0.5;
const int CA_AA = 1;
const float CA_WEIGHT = (float(CA_AA) * 2.0 + 1.0) * (float(CA_AA) * 2.0 + 1.0);
const float CA_OFFSET = 0.0001;

uniform float vignetting_amount: hint_range(0.0, 2.0) = 0.5;
uniform float vignetting_cos_power: hint_range(1.0, 20.0) = 4.0;
uniform float vignetting_brightness: hint_range(0.0, 2.0) = 1.05;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 adjust_hsv(vec3 col, float amount) {
    vec3 c = col;
    c = rgb2hsv(c);
    c = vec3(c.r, c.g, c.b * amount);
    c = hsv2rgb(c);
    return c;
}

vec2 scaling(vec2 uv, float scale) {
    return vec2((uv.x / scale) + (1.0 - (1.0 / scale)) * 0.5, (1.0 - (1.0 - uv.y) / scale) - (1.0 - (1.0 / scale)) * 0.5);
}

vec2 power_scaling(vec2 uv, float scale, float power, float distance_from_center) {
    float fixed_scale = (scale - 1.0) * pow(distance_from_center, power - 1.0) + 1.0;
    return scaling(uv, fixed_scale);
}

vec3 vignetting(vec3 col, float amount, float cos_power, float brightness, float distance_from_center) {
    vec3 c = adjust_hsv(col, pow(cos(distance_from_center * amount), cos_power) * brightness);
    return c;
}

float get_distance(vec2 uv, float aspect) {
    vec2 vdif = vec2(abs(uv.x - 0.5) * aspect, abs(uv.y - 0.5));
    float max_length = length(vec2(0.5 * aspect, 0.5));
    return length(vdif) / max_length;
}

void fragment() {
    
    vec3 col = vec3(0.0);
    float aspect = 1.0 / (TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y);
    float distance_from_center = get_distance(UV, radial ? aspect : 1.0);
    
    // 色収差
    vec2 uv_r = UV;
    vec2 uv_g = power_scaling(UV, 1.0 + chromatic_aberration_scale * chromatic_aberration_bias, chromatic_aberration_power, distance_from_center);
    vec2 uv_b = power_scaling(UV, 1.0 + chromatic_aberration_scale, chromatic_aberration_power, distance_from_center);

    for(int x = -CA_AA; x <= CA_AA; x++) {
        for(int y = -CA_AA; y <= CA_AA; y++) {
            vec2 aa_offset = vec2(float(x), float(y)) * CA_OFFSET;
            col.g += texture(TEXTURE, uv_g + aa_offset).g;
            col.b += texture(TEXTURE, uv_b + aa_offset).b;
        }
    }
    col.g /= CA_WEIGHT;
    col.b /= CA_WEIGHT;
    col.r = texture(TEXTURE, uv_r).r;
    
    // 周辺光量減衰
    col = vignetting(col, vignetting_amount, vignetting_cos_power, vignetting_brightness, distance_from_center);
        
    COLOR.rgb = col;
}