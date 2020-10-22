/**
 * Lacerta Post Processing
 * LC RGB2YUV
 * Version 1.0.0.0
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform float noise_amount: hint_range(0.0, 1.0) = 0.2;
uniform float saturation: hint_range(0.0, 1.0) = 0.8;
uniform float rgb_offset: hint_range(0.0, 20.0) = 10.0;
uniform float rgb_amount: hint_range(0.0, 1.0) = 0.5;

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

vec3 rgb2yuv(vec3 c) {
    float y = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    float u = 0.492 * (c.b - y);
    float v = 0.877 * (c.r - y);
    return vec3(y, u, v);
}

float overlay_calc(float c1, float c2) {
    if (c1 <= 0.5) {
        return c1 * c2 / 0.5;
    } else {
        return -1.0 + 2.0 * (c1 + c2) - c1 * c2 / 0.5;
    }
}

vec3 overlay(vec3 c1, vec3 c2) {
    return vec3(overlay_calc(c1.r, c2.r), overlay_calc(c1.g, c2.g), overlay_calc(c1.b, c2.b));
}

float noise(vec2 v) {
    return fract(1e4 * sin(17.0 * v.x + v.y * 0.1) * (0.1 + abs(sin(v.y * 13.0 + v.x))));
}

void fragment() {    
    vec3 col = texture(TEXTURE, UV).rgb;
    col += vec3(
        texture(TEXTURE, vec2(UV.x + rgb_offset * TEXTURE_PIXEL_SIZE.x, UV.y)).r,
        texture(TEXTURE, UV).g,
        texture(TEXTURE, vec2(UV.x - rgb_offset * TEXTURE_PIXEL_SIZE.x, UV.y)).b
    ) * rgb_amount;
    col *= 1.0 / (1.0 + rgb_amount);
    col = mix(col, overlay(col, vec3(noise(UV * TIME))), noise_amount);
    col = rgb2hsv(col);
    col.g = col.g * saturation;
    col = hsv2rgb(col);
    col = rgb2yuv(col);
    COLOR.rgb = col.rgb;
}