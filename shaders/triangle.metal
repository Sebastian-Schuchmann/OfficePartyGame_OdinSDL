#include <metal_stdlib>
using namespace metal;

struct VertIn {
    float3 pos [[attribute(0)]];
    float4 col [[attribute(1)]];
};

struct VertOut {
    float4 pos [[position]];
    float4 col;
};

vertex VertOut vert_main(VertIn in [[stage_in]],
                         constant float4x4& mvp [[buffer(0)]]) {
    VertOut out;
    out.pos = mvp * float4(in.pos, 1);
    out.col = in.col;
    return out;
}

fragment float4 frag_main(VertOut in [[stage_in]]) {
    return in.col;
}
