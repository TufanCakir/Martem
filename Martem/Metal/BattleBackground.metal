//
//  BattleBackground.metal
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

#include <metal_stdlib>
using namespace metal;

// A restrained brushed-steel surface with moving highlights and electrical veins.
[[ stitchable ]] half4 battleMetal(float2 position, float2 size, float time, half4 arenaColor) {
    float2 uv = position / max(size, float2(1.0));
    float brush = sin(position.y * 1.8) * 0.018 + sin(position.y * 0.37) * 0.025;
    float sweep = exp(-pow((uv.x + uv.y * 0.45 - fmod(time * 0.08, 1.8) + 0.3) * 7.0, 2.0));
    float veinX = 0.53 + 0.12 * sin(uv.y * 15.0 + time * 0.5) + 0.035 * sin(uv.y * 53.0);
    float lightning = exp(-abs(uv.x - veinX) * 110.0) * (0.25 + 0.2 * sin(time * 2.0));
    float vignette = 1.0 - 0.7 * length(uv - 0.5);
    float3 tint = float3(arenaColor.rgb) * 2.0;
    float3 steel = float3(0.035, 0.045, 0.06) + brush + sweep * 0.11;
    float3 color = (steel + tint * (0.25 + sweep * 0.45) + lightning * tint) * max(vignette, 0.25);
    return half4(half3(max(color, 0.0)), 1.0h);
}
