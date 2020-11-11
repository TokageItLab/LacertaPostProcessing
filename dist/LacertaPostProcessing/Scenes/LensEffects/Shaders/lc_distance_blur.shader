/**
 * Lacerta Post Processing
 * LC Distance Blur
 * Version 1.0.0.1
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform bool radial = true;

uniform float blur_radius: hint_range(0.0001, 20.0) = 10.0;
uniform float blur_power: hint_range(1.0, 10.0) = 5.0;
const int MAX_ITERATION = 3; // (MAX_ITERATION * 2) ^ 2

float get_distance(vec2 uv, float aspect) {
    vec2 vdif = vec2(abs(uv.x - 0.5), abs(uv.y - 0.5) * aspect);
    float max_length = length(vec2(0.5 * aspect, 0.5));
    return length(vdif) / max_length;
}

void fragment() {

    vec3 col = vec3(0.0);
    float aspect = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
    float distance_from_center = get_distance(UV, radial ? aspect : 1.0);
    
    float radius = pow(distance_from_center, blur_power - 1.0) * blur_radius;
    int fixed_radius = min(int(round(radius)), MAX_ITERATION);
    
    if (fixed_radius > 0) {
        for(int x = -fixed_radius; x <= fixed_radius; x++) {
            for(int y = -fixed_radius; y <= fixed_radius; y++) {
                vec2 uv = UV + vec2(float(x) * TEXTURE_PIXEL_SIZE.x, float(y) * TEXTURE_PIXEL_SIZE.y) * radius / float(fixed_radius);
                col += texture(TEXTURE, uv).rgb;
            }
        }        
        int weight = (fixed_radius * 2 + 1) * (fixed_radius * 2 + 1);
        col /= float(weight);
    } else {
        col = texture(TEXTURE, UV).rgb;
    }

    COLOR.rgb = col.rgb;
}