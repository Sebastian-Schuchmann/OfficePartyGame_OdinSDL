#include <metal_stdlib>
using namespace metal;

struct VertIn {
    float3 pos    [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv     [[attribute(2)]];
};

struct VertOut {
    float4 clip_pos  [[position]];
    float3 world_pos;
    float3 world_norm;
};

// Matches engine.VertUniforms (128 + 16 bytes = 144 bytes)
struct VertUniforms {
    float4x4 mvp;
    float4x4 model;
    float3   cam_pos;
    float    _pad;
};

// Matches engine.LitMatUniforms
struct LitMat {
    float4 albedo;
    float  specular;
    float  shininess;
    float2 _pad;
};

// Matches engine.DirLight
struct DirLight {
    float3 direction;
    float  _pad0;
    float3 color;
    float  ambient;
};

vertex VertOut vert_main(VertIn in [[stage_in]],
                         constant VertUniforms& u [[buffer(0)]]) {
    VertOut out;
    float4 world = u.model * float4(in.pos, 1.0);
    out.clip_pos  = u.mvp * float4(in.pos, 1.0);
    out.world_pos = world.xyz;
    // Normal matrix: for uniform-scale models, mat3(model) is fine.
    out.world_norm = normalize((u.model * float4(in.normal, 0.0)).xyz);
    return out;
}

fragment float4 frag_main(VertOut in          [[stage_in]],
                           constant LitMat&   mat   [[buffer(0)]],
                           constant DirLight& light [[buffer(1)]],
                           constant VertUniforms& u [[buffer(2)]]) {
    float3 N = normalize(in.world_norm);
    float3 L = normalize(-light.direction);
    float3 V = normalize(u.cam_pos - in.world_pos);
    float3 H = normalize(L + V);

    float diff = max(dot(N, L), 0.0);
    float spec = 0.0;
    if (mat.shininess > 0.0) {
        spec = pow(max(dot(N, H), 0.0), mat.shininess) * mat.specular;
    }

    float3 albedo   = mat.albedo.rgb;
    float3 ambient  = light.ambient * albedo;
    float3 diffuse  = diff * light.color * albedo;
    float3 specular = spec * light.color;

    return float4(ambient + diffuse + specular, mat.albedo.a);
}
