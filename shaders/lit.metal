#include <metal_stdlib>
using namespace metal;

struct VertIn {
    float3 pos    [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv     [[attribute(2)]];
};

struct VertOut {
    float4 clip_pos    [[position]];
    float3 world_pos;
    float3 world_norm;
    float4 light_space_pos;
};

struct VertUniforms {
    float4x4 mvp;
    float4x4 model;
    float3   cam_pos;
    float    _pad;
};

struct LightSpaceUniforms {
    float4x4 light_vp;
};

struct LitMat {
    float4 albedo;
    float  specular;
    float  shininess;
    float2 _pad;
};

struct DirLight {
    float3 direction;
    float  _pad0;
    float3 color;
    float  ambient;
};

vertex VertOut vert_main(VertIn in [[stage_in]],
                         constant VertUniforms& u       [[buffer(0)]],
                         constant LightSpaceUniforms& l [[buffer(1)]]) {
    VertOut out;
    float4 world    = u.model * float4(in.pos, 1.0);
    out.clip_pos    = u.mvp * float4(in.pos, 1.0);
    out.world_pos   = world.xyz;
    out.world_norm  = normalize((u.model * float4(in.normal, 0.0)).xyz);
    out.light_space_pos = l.light_vp * world;
    return out;
}

static float shadow_factor(texture2d<float> shadow_map, sampler smp, float4 light_space_pos) {
    // Perspective divide + map from [-1,1] to [0,1]
    float3 proj = light_space_pos.xyz / light_space_pos.w;
    float2 uv   = proj.xy * 0.5 + 0.5;
    uv.y = 1.0 - uv.y; // flip Y for Metal (NDC Y+ up, UV Y+ down)

    // Outside shadow map = fully lit
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 1.0;
    if (proj.z < 0.0 || proj.z > 1.0) return 1.0;

    float depth    = shadow_map.sample(smp, uv).r;
    float bias     = 0.005;
    return (proj.z - bias > depth) ? 0.35 : 1.0; // in shadow = 35% lit (ambient keeps some light)
}

fragment float4 frag_main(VertOut in                         [[stage_in]],
                           constant LitMat&             mat   [[buffer(0)]],
                           constant DirLight&            light [[buffer(1)]],
                           constant VertUniforms&        u     [[buffer(2)]],
                           texture2d<float>              shadow_map [[texture(0)]],
                           sampler                       shadow_smp [[sampler(0)]]) {
    float3 N = normalize(in.world_norm);
    float3 L = normalize(-light.direction);
    float3 V = normalize(u.cam_pos - in.world_pos);
    float3 H = normalize(L + V);

    float shadow = shadow_factor(shadow_map, shadow_smp, in.light_space_pos);

    float diff = max(dot(N, L), 0.0) * shadow;
    float spec = 0.0;
    if (mat.shininess > 0.0) {
        spec = pow(max(dot(N, H), 0.0), mat.shininess) * mat.specular * shadow;
    }

    float3 albedo   = mat.albedo.rgb;
    float3 ambient  = light.ambient * albedo;
    float3 diffuse  = diff * light.color * albedo;
    float3 specular = spec * light.color;

    return float4(ambient + diffuse + specular, mat.albedo.a);
}
