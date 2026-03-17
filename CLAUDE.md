# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
odin run .        # build and run
odin build .      # build only
```

No test framework — verify behavior by running the game.

**Important:** All `.odin` files must stay in the root directory. Odin packages are directory-bound — subdirectories are separate packages and cannot share global state with `package main`.

## Architecture
- Simple, Handmade Hero style, fat structs, no OOP

Single Odin package (`package main`) — all files in root:

- **`main.odin`** — SDL3 window init, main loop, input polling, FPS debug overlay. Global state: `window`, `dt_ms`, `WINDOW_WIDTH`, `WINDOW_HEIGHT` (updated on resize), WASD/QE bools, `mouse_dx/dy`, `mouse_locked`. Press `B` to toggle `DEBUG`. ESC unlocks mouse, click re-locks.
- **`gpu.odin`** — SDL3 GPU API: device, pipeline, vertex buffer, frame lifecycle (`gpu_begin_frame` / `gpu_end_frame`), `gpu_draw_triangle`.
- **`game.odin`** — Game state globals: `camera`, `triangles`, `player` Dings, `proj_mat`, `view_proj_mat`. `game_init` builds projection from `camera.fov`; `game_loop` calls `camera_update()` then dispatches draw calls.
- **`camera.odin`** — `camera_update()`: mouse look, WASD/QE movement, writes `view_proj_mat`.
- **`math.odin`** — `Vec3`, `Mat4` + constructors: `mat4_identity`, `mat4_translate`, `mat4_translate3`, `mat4_view(pos, yaw, pitch)`, `mat4_perspective`, `mat4_ortho`.
- **`ding.odin`** — `Vec2`, `Ding` fat struct (universal entity), movement, collision.
- **`colors.odin`** — `Color` struct (RGBA u8) and named color constants.

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

### Key conventions
- Global mutable state is intentional and pervasive (`dt_ms`, input flags, `view_proj_mat`).
- `dt_ms` is frame delta in **milliseconds**. For units/sec speeds: `speed * dt_ms / 1000`.
- World space is perspective, `(0,0,0)` = origin. Camera starts at origin looking down -Z.
- MVP = `view_proj_mat * mat4_translate3(world_pos)` — built per draw call in `gpu_draw_triangle`.
- `WINDOW_WIDTH` / `WINDOW_HEIGHT` are mutable globals, updated on `WINDOW_RESIZED` events.
