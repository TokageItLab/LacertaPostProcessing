/**
 * Lacerta Post Processing
 * LC Color Grading
 * Version 1.0.0.3
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform float pre_hue: hint_range(0.0, 2.0) = 1.0;
uniform float pre_saturation: hint_range(0.0, 2.0) = 1.0;
uniform float pre_brightness: hint_range(0.0, 2.0) = 1.0;

uniform uint curve_rgb_type = 0;
uniform float curve_rgb_weight: hint_range(0.0, 1.0) = 0.5;
uniform bool curve_rgb_s_form = true;
uniform sampler2D curve_rgb_texture: hint_black;

uniform uint curve_r_type = 0;
uniform float curve_r_weight: hint_range(0.0, 1.0) = 0.5;
uniform bool curve_r_s_form = true;
uniform sampler2D curve_r_texture: hint_black;

uniform uint curve_g_type = 0;
uniform float curve_g_weight: hint_range(0.0, 1.0) = 0.5;
uniform bool curve_g_s_form = true;
uniform sampler2D curve_g_texture: hint_black;

uniform uint curve_b_type = 0;
uniform float curve_b_weight: hint_range(0.0, 1.0) = 0.5;
uniform bool curve_b_s_form = true;
uniform sampler2D curve_b_texture: hint_black;

uniform float post_hue: hint_range(0.0, 2.0) = 1.0;
uniform float post_saturation: hint_range(0.0, 2.0) = 1.0;
uniform float post_brightness: hint_range(0.0, 2.0) = 1.0;

uniform float overlay_amount: hint_range(0.0, 1.0) = 0.0;
uniform sampler2D overlay_texture: hint_white;

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

float bias(float b, float x) {
    return pow(x, log(b) / log(0.5));
}

float inv_bias(float b, float x) {
    return 1.0 - pow(1.0 - x, log(1.0 - b) / log(0.5));
}

float cos_bias(float b, float x) {
    float nb = b * 2.0;
    if (b <= 0.5) {
        nb = 1.0 - nb;
        return mix(x, 1.0 - cos(x), nb);
    } else {
        nb = nb - 1.0;
        return mix(x, cos(x), nb);
    }
}

float gain(float g, float x) {
    if (x < 0.5) {
        return bias(1.0 - g, 2.0 * x) / 2.0;
    } else {
        return 1.0 - bias(1.0 - g, 2.0 - 2.0 * x) / 2.0;
    }
}

float inv_gain(float g, float x) {
    if (x < 0.5) {
        return inv_bias(1.0 - g, 2.0 * x) / 2.0;
    } else {
        return 1.0 - inv_bias(1.0 - g, 2.0 - 2.0 * x) / 2.0;
    }
}

float cos_gain(float g, float x) {
    if (x < 0.5) {
        return cos_bias(1.0 - g, 2.0 * x) / 2.0;
    } else {
        return 1.0 - cos_bias(1.0 - g, 2.0 - 2.0 * x) / 2.0;
    }
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

float get_value_of_spline(uint type, float x, float weight, bool s_form, sampler2D curve_tex) {
    float y = 0.0;
    int nt = min(max(0, int(type)), 3);
    switch (nt) {
        case 0:
            if (s_form) {
                y = cos_gain(weight, x);
            } else {
                y = cos_bias(weight, x);
            }
            break;
        case 1:
            if (s_form) {
                y = gain(weight, x);
            } else {
                y = bias(weight, x);
            }
            break;
        case 2:
            if (s_form) {
                y = inv_gain(weight, x);
            } else {
                y = inv_bias(weight, x);
            }
            break;
        case 3:
            y = texture(curve_tex, vec2(x, 0)).r;
            break;
    }
    return y;
}

void fragment() {
    vec3 col = texture(TEXTURE, UV).rgb;

    col = rgb2hsv(col);
    col = vec3(col.r * pre_hue, col.g * pre_saturation, col.b * pre_brightness);
    col = hsv2rgb(vec3(col.r, col.g, col.b));

    col = vec3(
        get_value_of_spline(curve_r_type, col.r, curve_r_weight, curve_r_s_form, curve_r_texture),
        get_value_of_spline(curve_g_type, col.g, curve_g_weight, curve_g_s_form, curve_g_texture),
        get_value_of_spline(curve_b_type, col.b, curve_b_weight, curve_b_s_form, curve_b_texture)
    );

    col = rgb2hsv(col);
    col.b = get_value_of_spline(curve_rgb_type, col.b, curve_rgb_weight, curve_rgb_s_form, curve_rgb_texture);
    col = vec3(col.r * post_hue, col.g * post_saturation, col.b * post_brightness);
    col = hsv2rgb(vec3(col.r, col.g, col.b));

    col = mix(col, overlay(col, texture(overlay_texture, UV).rgb), overlay_amount);

    COLOR.rgb = col.rgb;
}