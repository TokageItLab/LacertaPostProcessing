/**
 * Lacerta Post Processing
 * LC Tape Distortion
 * Version 1.0.0.2
 * Copyright (c) 2020-2021, Silc Tokage Renew / Tokage IT Lab.
 * MIT License
 */
shader_type canvas_item;

uniform float wave_noise_amount: hint_range(0.0, 10.0) = 1.5;
uniform float wave_amount: hint_range(0.0, 0.1) = 0.01;
uniform float wave_spike: hint_range(1.0, 10000.0) = 3000.0;
uniform float wave_speed: hint_range(0.0, 10.0) = 0.5;
uniform float wave_unison_offset: hint_range(0.0, 1.0) = 0.17;

float noise(vec2 v) {
    return fract(1e4 * sin(17.0 * v.x + v.y * 0.1) * (0.1 + abs(sin(v.y * 13.0 + v.x))));
}

float wave(float time, float offset) {
    // add 5 times
    float o = 0.0;
    for (int i = 0; i < 5; i++) {
        float c = sin((time + offset + (wave_unison_offset * float(i))) * wave_speed * float(i));
        c = c < 0.0 ? -pow(c, wave_spike) : pow(c, wave_spike);
        o += c;
    }
    // normalize
    o *= 0.2;
    return o;
}

void fragment() {
    vec3 col = vec3(0.0);
    vec2 uv = UV;
    uv.x += (noise(vec2(uv.y, TIME)) - 0.5) * wave_noise_amount * TEXTURE_PIXEL_SIZE.x;
    uv.x += wave(TIME, uv.y) * wave_amount;
    col = texture(TEXTURE, uv).rgb;
    COLOR.rgb = col.rgb;
}