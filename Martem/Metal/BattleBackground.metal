//
//  BattleBackground.metal
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 battleMetal(float2 position, float2 size, float time,
                                   half4 background, half4 accent, half4 highlight, half4 metal,
                                   float speed, float brushIntensity, float sweepIntensity,
                                   float lightningIntensity, float vignetteIntensity, float brightness) {
    float2 uv = position / max(size, float2(1.0));
    float brush = (sin(position.y * 1.8) * 0.018 + sin(position.y * 0.37) * 0.025) * brushIntensity;
    float sweep = exp(-pow((uv.x + uv.y * 0.45 - fmod(time * speed, 1.8) + 0.3) * 7.0, 2.0));
    float veinX = 0.53 + 0.12 * sin(uv.y * 15.0 + time * 0.15) + 0.035 * sin(uv.y * 53.0);
    float lightning = exp(-abs(uv.x - veinX) * 110.0) * lightningIntensity;
    float vignette = max(0.2, 1.0 - vignetteIntensity * length(uv - 0.5));
    float3 color = float3(background.rgb) + brush * float3(metal.rgb)
                 + sweep * sweepIntensity * 0.15 * (float3(metal.rgb) + float3(highlight.rgb) * 0.15)
                 + lightning * float3(accent.rgb);
    return half4(half3(max(color * vignette * brightness, 0.0)), 1.0h);
}
