#include <metal_stdlib>
using namespace metal;

struct VertIn {
    float3 pos    [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv     [[attribute(2)]];
};

struct VertOut {
    float4 pos [[position]];
};

struct VertUniforms {
    float4x4 mvp;
    float4x4 model;
};

struct UnlitMat {
    float4 color;
};

vertex VertOut vert_main(VertIn in [[stage_in]],
                         constant VertUniforms& u [[buffer(0)]]) {
    VertOut out;
    out.pos = u.mvp * float4(in.pos, 1.0);
    return out;
}

fragment float4 frag_main(VertOut in [[stage_in]],
                          constant UnlitMat& mat [[buffer(0)]]) {
    return mat.color;
}
