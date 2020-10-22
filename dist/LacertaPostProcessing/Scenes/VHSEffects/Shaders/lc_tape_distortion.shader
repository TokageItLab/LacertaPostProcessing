/**
 * Lacerta Post Processing
 * LC Tape Distortion
 * Version 1.0.0.0
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform float wave_amount: hint_range(0.0, 10.0) = 3.0;

float noise(vec2 v) {
    return fract(1e4 * sin(17.0 * v.x + v.y * 0.1) * (0.1 + abs(sin(v.y * 13.0 + v.x))));
}

void fragment() {
    vec3 col = vec3(0.0);
    vec2 uv = UV;
    uv.x += (noise(vec2(uv.y, TIME)) - 0.5) * wave_amount * TEXTURE_PIXEL_SIZE.x;
    col = texture(TEXTURE, uv).rgb;
    COLOR.rgb = col.rgb;
}