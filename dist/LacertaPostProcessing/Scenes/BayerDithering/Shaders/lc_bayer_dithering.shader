/**
 * Lacerta Post Processing
 * LC Bayer Dithering
 * Version 1.0.0.1
 * Copyright (c) 2020, Silc Renew / Tokage IT Lab.
 * All rights reserved.
 */
shader_type canvas_item;

uniform bool monochrome = true;
uniform int pixel_size = 1;
uniform bool use_average = true;

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

float get_bayer(int index) {
    switch (index) {
        case 0:
            return 0.0625;
        case 1:
            return 0.5625;
        case 2:
            return 0.1875;
        case 3:
            return 0.6875;
        case 4:
            return 0.8125;
        case 5:
            return 0.3125;
        case 6:
            return 0.9375;
        case 7:
            return 0.4375;
        case 8:
            return 0.25;
        case 9:
            return 0.75;
        case 10:
            return 0.125;
        case 11:
            return 0.625;
        case 12:
            return 1.0;
        case 13:
            return 0.5;
        case 14:
            return 0.875;
        case 15:
            return 0.375;
        default:
            return 0.0;
    }
}

void fragment() {
    int pixel_x = int(ceil(UV.x / TEXTURE_PIXEL_SIZE.x));
    int pixel_y = int(ceil(UV.y / TEXTURE_PIXEL_SIZE.y));
    int fixed_pixel_x = pixel_x / pixel_size;
    int fixed_pixel_y = pixel_y / pixel_size;
    int offset_x = pixel_x % pixel_size;
    int offset_y = pixel_y % pixel_size;

    vec3 col = vec3(0.0);
    if (use_average) {
        vec3 dest = vec3(0.0);
        for (int x = 0; x < pixel_size; x++) {
            for (int y = 0; y < pixel_size; y++) {
                dest += texture(
                    TEXTURE,
                    vec2(
                        (UV.x - float(offset_x) * TEXTURE_PIXEL_SIZE.x) + TEXTURE_PIXEL_SIZE.x * float(x),
                        (UV.y - float(offset_y) * TEXTURE_PIXEL_SIZE.y) + TEXTURE_PIXEL_SIZE.y * float(y)
                    )
                ).rgb;
            }
        }
        col = dest / float(pixel_size * pixel_size);
    } else {
        col = texture(
            TEXTURE,
            vec2(
                (UV.x - float(offset_x) * TEXTURE_PIXEL_SIZE.x),
                (UV.y - float(offset_y) * TEXTURE_PIXEL_SIZE.y)
            )
        ).rgb;
    }
    
    if (monochrome) {
        col = rgb2hsv(col);
        col = vec3(col.r, 0.0, col.b);
        col = hsv2rgb(vec3(col.r, col.g, col.b));        
    }

    int x = fixed_pixel_x % 4;
    int y = fixed_pixel_y % 4;        
    int index = x + y * 4;
    float limit = get_bayer(index);

    if (monochrome) {
        if (col.r < limit) {
            col = vec3(0.0);
        } else {
            col = vec3(1.0);
        }
    } else {
        if (col.r >= limit) {
            if (col.g >= limit) {
                if (col.b >= limit) {
                    col = vec3(1.0);
                } else {
                    col = vec3(1.0, 1.0, 0.0);
                }
            } else if (col.b >= limit) {
                col = vec3(1.0, 0.0, 1.0);
            } else {
                col = vec3(1.0, 0.0, 0.0);
            }
        } else if (col.g >= limit) {
            if (col.b >= limit) {
                col = vec3(0.0, 1.0, 1.0);
            } else {
                col = vec3(0.0, 1.0, 0.0);
            }
        } else if (col.b >= limit) {
            col = vec3(0.0, 0.0, 1.0);
        } else {
            col = vec3(0.0);
        }
    }

    COLOR.rgb = col.rgb;
}