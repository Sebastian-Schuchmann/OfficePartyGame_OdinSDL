# 3D Engine Design Document

## Philosophy
Code-first. Handmade Hero style. Fat structs, global state, no OOP.
Small feature → `odin run .` → approve → commit → next.

---

## Architecture

| File | Owns |
|---|---|
| `main.odin` | Window, main loop, input, delta time |
| `gpu.odin` | GPU device, pipeline, vertex buffer, frame lifecycle, draw calls |
| `game.odin` | Game state, camera, view-projection matrix, game loop |
| `math.odin` | `Mat4`, `mat4_identity`, `mat4_translate`, `mat4_ortho` |
| `ding.odin` | `Vec2`, `Ding` struct, movement, collision |
| `colors.odin` | Color constants |

---

## GPU Frame Lifecycle (SDL3 GPU API)

```
gpu_begin_frame()
  AcquireGPUCommandBuffer
  AcquireGPUSwapchainTexture  ← returns nil when minimized, skip frame
  BeginGPURenderPass
  BindGPUGraphicsPipeline

  game_loop()  ← draw calls go here

gpu_end_frame()
  EndGPURenderPass
  SubmitGPUCommandBuffer
```

---

## Milestone Roadmap

| # | Status | Goal |
|---|---|---|
| 0 | ✅ | **Triangle** — shader-baked positions, no vertex buffer |
| 1 | ✅ | **Vertex + Uniform buffer** — `Vertex` struct, GPU upload, MVP matrix pushed as uniform, movable triangle |
| 2 | ✅ | **Camera + Math** — `mat4_ortho` (centered, 1 unit = 1 px), `camera_pos`, `view_proj_mat`, 300 px/s movement |
| 3 | | Mesh system (quad/sprite, index buffer, `render_ding` → GPU draw) |
| 4 | | Multiple Dinge rendered via GPU (depth buffer if needed) |
| 5 | | Textures + sampler (PNG loading, textured sprites) |

---

## Shader Strategy
- All shaders live in `shaders/` as `.metal` files, loaded at startup via `os.read_entire_file`
- One `.metal` file per render pass / effect

---

## Ding Evolution (Milestone 3+)
```odin
Ding :: struct {
    pos:   Vec3,
    rot:   Vec3,  // Euler angles in degrees
    scale: Vec3,
    color: Color,
    speed: f32,
    type:  DingType,
}
```
Until then, 2D Ding fields stay as-is.
