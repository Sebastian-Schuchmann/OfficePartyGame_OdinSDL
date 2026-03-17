# 3D Engine Design Document

## Philosophy
Code-first. Handmade Hero style. Fat structs, global state, no OOP.
Small feature → `odin run .` → approve → commit → next.

---

## Architecture

| File | Owns |
|---|---|
| `main.odin` | Window, main loop, input, delta time, mouse lock, resize handling |
| `gpu.odin` | GPU device, pipeline, vertex buffer, frame lifecycle, draw calls |
| `game.odin` | Game state globals (`camera`, `triangles`, `player`), `proj_mat`, game loop |
| `camera.odin` | `camera_update()` — mouse look, WASD movement, builds `view_proj_mat` |
| `math.odin` | `Vec3`, `Mat4`, `mat4_view`, `mat4_perspective`, `mat4_ortho`, transforms |
| `ding.odin` | `Ding` fat struct, `DingType`, `Vec2`, movement, collision |
| `colors.odin` | `Color` struct, named color constants |

---

## GPU Frame Lifecycle (SDL3 GPU API)

```
gpu_begin_frame()
  AcquireGPUCommandBuffer
  AcquireGPUSwapchainTexture  ← returns nil when minimized, skip frame
  BeginGPURenderPass
  BindGPUGraphicsPipeline

  game_loop()  ← draw calls go here
    camera_update()
    for each triangle: gpu_draw_triangle(pos3)

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
| 2 | ✅ | **Fly-cam** — perspective projection, `mat4_view`, WASD+mouse look, multiple triangles, Ding-based camera, mouse lock/unlock |
| 3 | | Mesh system (quad/sprite, index buffer, `render_ding` → GPU draw) |
| 4 | | Multiple Dinge rendered via GPU (depth buffer if needed) |
| 5 | | Textures + sampler (PNG loading, textured sprites) |

---

## Shader Strategy
- All shaders live in `shaders/` as `.metal` files, loaded at startup via `os.read_entire_file`
- One `.metal` file per render pass / effect
