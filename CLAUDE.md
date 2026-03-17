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
  - `ding.odin` — `Ding` fat struct, `DingType`, `GpuMesh` ref, movement and collision procs.
  - `colors.odin` — `Color` struct (RGBA u8) and named color constants.
  - `gpu.odin` — SDL3 GPU API: device, pipeline, depth buffer, frame lifecycle. `gpu_init(window)`, `gpu_begin_frame(window)`, `gpu_end_frame()`, `gpu_create_mesh(verts, indices)`, `gpu_draw_mesh(mesh, pos, vpm)`, `gpu_draw_ding(ding, vpm)`.
- **`package game`** (`game/`) — imports `engine`. Owns game state globals.
  - `game.odin` — `Input` struct, globals: `camera`, `scene`, `player`, `proj_mat`, `view_proj_mat`. `game_init(w, h)` builds meshes and populates `scene`; `game_loop(input)` calls `camera_update` then draws all Dings in `scene`. `on_resize(w, h)` recomputes `proj_mat`.
  - `camera.odin` — fly-cam: mouse look, full 3D WASD + Q/E up-down, writes `view_proj_mat`.
  - `physics.odin` — grounded physics (gravity, jump) saved for future re-integration; all code is commented out.

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

**Rule: if it appears on screen, it must be a `Ding` in `game.scene`. No exceptions except the camera and player (which are Dings but managed separately).**

`Ding` is the only entity type. Every game object is a `Ding` — floor, walls, triangles, obstacles, collectables, etc. All possible properties live on every `Ding`; unused fields are zero. No inheritance, no interfaces.

```
// 2D
pos:    Vec2       — 2D screen position
color:  Color
width, height: f32

// 3D
pos3:  Vec3        — world position
vel3:  Vec3        — 3D velocity (e.g. for physics)
yaw:   f32         — horizontal rotation (radians)
pitch: f32         — vertical rotation (radians)
roll:  f32
mesh:  GpuMesh     — GPU mesh (zero if unused; gpu_draw_ding no-ops if vertex_buf == nil)

// Camera-specific
fov:               f32   — field of view (radians)
mouse_sensitivity: f32   — radians per pixel

// Shared
speed:  f32
type:   DingType   — PLAYER, OBSTACLE, COLLECTABLE, CAMERA, TRIANGLE, PROP
active: bool
```

### Scene rendering
`game.scene: [dynamic]Ding` — all 3D objects to render each frame.
`game_loop` calls `engine.gpu_draw_ding(d, view_proj_mat)` for every `d` in `scene`.
`gpu_draw_ding` draws `d.mesh` at `d.pos3` — no-op if `d.mesh.vertex_buf == nil`.

### Key conventions
- `dt_ms` is frame delta in **milliseconds** (owned by `main`, passed via `Input`). For units/sec speeds: `speed * dt_ms / 1000`.
- World space is perspective, `(0,0,0)` = origin. Camera starts at origin looking down -Z.
- MVP = `view_proj_mat * mat4_translate3(world_pos)` — built per draw call in `gpu_draw_mesh`.
- `WINDOW_WIDTH` / `WINDOW_HEIGHT` are mutable globals in `main`, updated on `WINDOW_RESIZED` events, passed to `game.on_resize`.
- Winding order: **CCW = front face**. All mesh faces must wind CCW when viewed from the direction the camera can see them.

## Milestones

| # | Status | Description |
|---|--------|-------------|
| 1 | ✅ | Vertex buffer + uniform buffer, movable triangle |
| 2 | ✅ | Fly-cam, Ding fat struct, mouse lock, resize fix |
| 3 | ✅ | Depth buffer — proper z-sorting, no more triangle bleed-through |
| 4 | ✅ | Indexed meshes + floor plane (`GpuMesh`, `gpu_create_mesh`, `gpu_draw_mesh`) |
| 5 | ✅ | Backface culling (CCW front-face), correct vertex attribute offset |
| 6 | ✅ | Fly-cam restored. Grounded physics saved in `physics.odin` for later |
| 7 | ✅ | Office room geometry (4 walls + ceiling) — everything a `Ding` in `scene` |
| 8 | 🔲 | Party game mechanics (objectives, scoring) |
