#include <metal_stdlib>
using namespace metal;

// Depth-only shadow pass — outputs only clip position.
// No fragment output needed; depth is written automatically.

struct VertIn {
    float3 pos    [[attribute(0)]];
    float3 normal [[attribute(1)]];  // unused but must match pipeline layout
    float2 uv     [[attribute(2)]];  // unused
};

struct ShadowUniforms {
    float4x4 light_space; // light projection * light view * model
};

vertex float4 vert_main(VertIn in [[stage_in]],
                        constant ShadowUniforms& u [[buffer(0)]]) {
    return u.light_space * float4(in.pos, 1.0);
}

// Trivial fragment shader — SDL3 GPU requires one even for depth-only passes.
fragment float4 frag_main() {
    discard_fragment();
    return float4(0);
}
