/**
 * Lacerta Post Processing
 * LC One Direction Blur
 * Version 1.0.0.0
 * Copyright (c) 2020-2021, Silc Tokage Renew / Tokage IT Lab.
 * MIT License
 */
shader_type canvas_item;

uniform bool use_average = true;
uniform vec4 blur_color: hint_color = vec4(0,0,0,0);
uniform float blur_direction: hint_range(0.0, 360.0) = 0.0;
uniform float blur_length: hint_range(0.0, 500.0) = 100;
uniform int blur_roughness: hint_range(1, 5) = 1;
uniform float attenuation_power: hint_range(0.01, 20) = 2.0;
uniform float lightness_threshold: hint_range(0.0, 1.0) = 0.9;
uniform bool invert_threshold = false;

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -0.3333, 0.6667, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void fragment() {
    int blur_step = int(blur_length / float(blur_roughness));
    float blur_step_length = blur_length / float(blur_step);
    float blur_step_ops = 1.0 / float(blur_step);

    float rad = radians(blur_direction);
    vec2 dir = vec2(cos(rad), sin(rad));

    vec3 col = vec3(0.0);
    col = texture(TEXTURE, UV).rgb;

    if (invert_threshold ? rgb2hsv(col).z > lightness_threshold : rgb2hsv(col).z < lightness_threshold) {
        for (int i = 1 ; i < blur_step; i++) {
            vec2 search_uv = vec2(
                UV.x - TEXTURE_PIXEL_SIZE.x * dir.x * blur_step_length * float(i),
                UV.y - TEXTURE_PIXEL_SIZE.y * dir.y * blur_step_length * float(i)
            );
            vec3 search_col = texture(TEXTURE, search_uv).rgb;
            if (invert_threshold ? rgb2hsv(search_col).z < lightness_threshold : rgb2hsv(search_col).z > lightness_threshold) {
                search_col = mix(search_col, blur_color.rgb, blur_color.a);
                col = mix(search_col, col, 1.0 - pow(1.0 - blur_step_ops * float(i), attenuation_power));
                break;
            }
        }
    } else {
        col = mix(col, blur_color.rgb, blur_color.a);
    }

    COLOR.rgb = col.rgb;
}