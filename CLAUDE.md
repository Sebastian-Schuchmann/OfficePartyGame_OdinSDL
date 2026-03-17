# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
odin run .        # build and run
odin build .      # build only
```

No test framework — verify behavior by running the game.

**Important:** Do NOT name a local package `core/` — it would shadow Odin's stdlib `core:` collection. Use `engine/` instead.

## Architecture
- Simple, Handmade Hero style, fat structs, no OOP

Three Odin packages:

- **`package main`** (`main.odin`) — SDL3 window init, main loop, input polling, FPS debug overlay. Owns globals: `window`, `dt_ms`, `WINDOW_WIDTH`, `WINDOW_HEIGHT` (updated on resize), WASD/QE bools, `mouse_dx/dy`, `mouse_locked`. Builds `game.Input` each frame and passes it to `game.game_loop`. Press `B` to toggle `DEBUG`. ESC unlocks mouse, click re-locks.
- **`package engine`** (`engine/`) — shared types and GPU. No dependency on `game` or `main`.
  - `math.odin` — `Vec2`, `Vec3`, `Mat4` + constructors: `mat4_identity`, `mat4_translate`, `mat4_translate3`, `mat4_view(pos, yaw, pitch)`, `mat4_perspective`, `mat4_ortho`.
  - `ding.odin` — `Ding` fat struct, `DingType`, movement and collision procs (take `dt_ms`, window dims as params — no globals).
  - `colors.odin` — `Color` struct (RGBA u8) and named color constants.
  - `gpu.odin` — SDL3 GPU API: device, pipeline, vertex buffer, frame lifecycle. `gpu_init(window)`, `gpu_begin_frame(window)`, `gpu_end_frame()`, `gpu_draw_triangle(pos, view_proj_mat)`.
- **`package game`** (`game/`) — imports `engine`. Owns game state globals.
  - `game.odin` — `Input` struct, globals: `camera`, `triangles`, `player`, `proj_mat`, `view_proj_mat`. `game_init(w, h)` builds projection; `game_loop(input)` calls `camera_update` then dispatches draw calls. `on_resize(w, h)` recomputes `proj_mat`.
  - `camera.odin` — `camera_update(input)`: mouse look, WASD/QE movement, writes `view_proj_mat`.

### Import convention
```odin
// in main.odin
import engine "./engine"
import game   "./game"

// in game/*.odin
import engine "../engine"
```

### Input flow
`main` owns all input globals → builds `game.Input{...}` each frame → passes to `game.game_loop(input)` → `camera_update(input)` consumes it. No input globals leak into sub-packages.

### Ding — the universal fat struct
`Ding` is the only entity type. Every game object is a `Ding` — player, camera, triangle, obstacle, etc. All possible properties live on every `Ding`; unused fields are zero. No inheritance, no interfaces.

```
// 2D
pos:    Vec2       — 2D screen position
color:  Color
width, height: f32

// 3D
pos3:  Vec3        — world position
yaw:   f32         — horizontal rotation (radians)
pitch: f32         — vertical rotation (radians)
roll:  f32

// Camera-specific
fov:               f32   — field of view (radians)
mouse_sensitivity: f32   — radians per pixel

// Shared
speed:  f32
type:   DingType   — PLAYER, OBSTACLE, COLLECTABLE, CAMERA, TRIANGLE
active: bool
```

## Milestones

| # | Status | Description |
|---|--------|-------------|
| 1 | ✅ | Vertex buffer + uniform buffer, movable triangle |
| 2 | ✅ | Fly-cam, Ding fat struct, mouse lock, resize fix |
| 3 | ✅ | Depth buffer — proper z-sorting, no more triangle bleed-through |
| 4 | 🔲 | Indexed meshes + floor plane (quads, `GpuMesh`, `gpu_create_mesh`, `gpu_draw_mesh`) |
| 5 | 🔲 | Backface culling + consistent winding order |
| 6 | 🔲 | Gravity + ground collision — player walks on a surface |
| 7 | 🔲 | Office room geometry (walls, ceiling, furniture as boxes) |
| 8 | 🔲 | Party game mechanics (objectives, scoring) |

### Key conventions
- `dt_ms` is frame delta in **milliseconds** (owned by `main`, passed via `Input`). For units/sec speeds: `speed * dt_ms / 1000`.
- World space is perspective, `(0,0,0)` = origin. Camera starts at origin looking down -Z.
- MVP = `view_proj_mat * mat4_translate3(world_pos)` — built per draw call in `engine.gpu_draw_triangle`.
- `WINDOW_WIDTH` / `WINDOW_HEIGHT` are mutable globals in `main`, updated on `WINDOW_RESIZED` events, passed to `game.on_resize`.
