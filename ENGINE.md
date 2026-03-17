# 3D Engine Design Document

## Philosophy
Code-first. Handmade Hero style. Fat structs, global state, no OOP.
Small feature → `odin run .` → approve → commit → next.

---

## Architecture

| File | Owns |
|---|---|
| `main.odin` | Window, main loop, input, delta time |
| `gpu.odin` | GPU device, pipeline, frame lifecycle |
| `game.odin` | Game state, entity arrays, game loop |
| `ding.odin` | `Ding` struct, movement, collision |
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

| # | Goal |
|---|---|
| 0 | **Triangle** — shader-baked positions, no vertex buffer |
| 1 | Vertex buffer + uniform buffer (MVP matrix, movable triangle) |
| 2 | Camera + math (Vec3, Mat4, perspective, WASD controls) |
| 3 | Mesh system (cube, index buffer, `render_ding` → GPU) |
| 4 | Depth buffer (multiple Dinge, no z-fighting) |
| 5 | Textures + sampler (textured cube, PNG loading) |

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
