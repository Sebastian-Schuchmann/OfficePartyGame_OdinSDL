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
  - `gpu.odin` — SDL3 GPU API: device, pipelines (unlit/lit/textured_lit), depth buffer, frame lifecycle. `gpu_init`, `gpu_begin_frame`, `gpu_end_frame`, `gpu_create_mesh`, `gpu_draw_ding`. Globals: `gpu_dir_light` (set by game each frame), `gpu_cam_pos` (set by camera_update).
  - `material.odin` — `Material` fat struct (all shader props in one; ShaderType selects pipeline), `DirLight`.
  - `obj.odin` — `obj_load(path)` — parses .obj files, fan-triangulates n-gons, computes flat normals if missing.
  - `texture.odin` — `gpu_load_texture(path)` — loads BMP, uploads to GPU; `gpu_default_sampler` (LINEAR/REPEAT).
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
mesh:     GpuMesh    — GPU mesh (zero if unused)
material: ^Material  — points into game.materials pool (nil = gpu_draw_ding no-ops)

// Camera-specific
fov:               f32   — field of view (radians)
mouse_sensitivity: f32   — radians per pixel

// Shared
speed:  f32
type:   DingType   — PLAYER, OBSTACLE, COLLECTABLE, CAMERA, TRIANGLE, PROP
active: bool
```

### Material system
Every rendered Ding needs a `material: ^Material`. Materials live in `game.materials[MAX_MATERIALS]` (pool of 64); get a pointer with `alloc_material()`.

`Material` is a fat struct — **all fields for all shaders live here, unused fields are zero**. Never split into per-shader structs.

`ShaderType` selects the pipeline per draw:
- `.UNLIT` — flat `material.color`, no lighting
- `.LIT` — Blinn-Phong, reads `engine.gpu_dir_light` and `engine.gpu_cam_pos`
- `.TEXTURED_LIT` — Blinn-Phong + BMP albedo texture via `material.albedo_tex`

### Scene rendering
`game.scene: [dynamic]Ding` — all 3D objects to render each frame.
`game_loop` calls `engine.gpu_draw_ding(d, view_proj_mat)` for every `d` in `scene`.
`gpu_draw_ding` no-ops if `d.mesh.vertex_buf == nil` or `d.material == nil`.

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
| 8 | ✅ | Material fat struct + Unlit shader pipeline |
| 9 | ✅ | OBJ mesh loading (`engine/obj.odin`, `assets/cube.obj`) |
| 10 | ✅ | Blinn-Phong lighting — directional light, specular, `engine.gpu_dir_light` |
| 11 | ✅ | Texture loading — BMP via SDL, `gpu_load_texture`, `TEXTURED_LIT` pipeline |
| 12 | 🔲 | Shadows — shadow map from directional light |
| 13 | 🔲 | Audio — SDL3 audio device, sound effect + music playback |
| 14 | 🔲 | Controller input — SDL3 gamepad, axis-to-movement mapping |
| 15 | 🔲 | Party game mechanics (objectives, scoring, rounds) |
