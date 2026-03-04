#include <metal_stdlib>
using namespace metal;

struct VertOut {
    float4 pos [[position]];
    float4 col;
};

vertex VertOut vert_main(uint vid [[vertex_id]]) {
    float2 positions[3] = { float2(0,0.5), float2(-0.5,-0.5), float2(0.5,-0.5) };
    float4 colors[3]    = { float4(1,0,0,1), float4(0,1,0,1), float4(0,0,1,1) };
    VertOut out;
    out.pos = float4(positions[vid], 0, 1);
    out.col = colors[vid];
    return out;
}

fragment float4 frag_main(VertOut in [[stage_in]]) {
    return in.col;
}