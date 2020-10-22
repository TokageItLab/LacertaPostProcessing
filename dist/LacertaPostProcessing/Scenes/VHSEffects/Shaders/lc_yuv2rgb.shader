/**
 * Lacerta Post Processing
 * LC YUV2RGB
 * Version 1.0.0.0
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform float u_blur_radius: hint_range(0.0001, 20.0) = 6.0;
uniform float v_blur_radius: hint_range(0.0001, 20.0) = 3.0;
const int MAX_ITERATION = 1; // (MAX_ITERATION * 2) ^ 2

vec3 yuv2rgb(vec3 c) {
float r = c.r + 1.140 * c.b;
float g = c.r - 0.395 * c.g - 0.581 * c.b;
float b = c.r + 2.032 * c.g;
    return vec3(r, g, b);
}

void fragment() {
    vec3 col = vec3(texture(TEXTURE, UV).r, 0.0, 0.0);

    int fixed_u_radius = min(int(round(u_blur_radius)), MAX_ITERATION);
    if (fixed_u_radius > 0) {
        for(int x = -fixed_u_radius; x <= fixed_u_radius; x++) {
            for(int y = -fixed_u_radius; y <= fixed_u_radius; y++) {
                vec2 uv = UV + vec2(float(x) * TEXTURE_PIXEL_SIZE.x, float(y) * TEXTURE_PIXEL_SIZE.y) * u_blur_radius / float(fixed_u_radius);
                col.g += texture(TEXTURE, uv).g;
            }
        }        
        int weight = (fixed_u_radius * 2 + 1) * (fixed_u_radius * 2 + 1);
        col.g /= float(weight);
    } else {
        col.g = texture(TEXTURE, UV).g;
    }

    int fixed_v_radius = min(int(round(v_blur_radius)), MAX_ITERATION);
    if (fixed_v_radius > 0) {
        for(int x = -fixed_v_radius; x <= fixed_v_radius; x++) {
            for(int y = -fixed_v_radius; y <= fixed_v_radius; y++) {
                vec2 uv = UV + vec2(float(x) * TEXTURE_PIXEL_SIZE.x, float(y) * TEXTURE_PIXEL_SIZE.y) * v_blur_radius / float(fixed_v_radius);
                col.b += texture(TEXTURE, uv).b;
            }
        }        
        int weight = (fixed_v_radius * 2 + 1) * (fixed_v_radius * 2 + 1);
        col.b /= float(weight);
    } else {
        col.b = texture(TEXTURE, UV).b;
    }

    col = yuv2rgb(col);
    COLOR.rgb = col.rgb;
}