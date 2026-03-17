# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
odin run .        # build and run
odin build .      # build only
```

No test framework — verify behavior by running the game.

## Architecture
- Simple, Handmade Hero style, fat structs, no OOP

Single Odin package (`package main`) split across files:

- **`main.odin`** — SDL3 window init, main loop, input polling, FPS debug overlay. Global state: `window`, `dt_ms`, arrow-key booleans. Press `B` to toggle `DEBUG`.
- **`gpu.odin`** — SDL3 GPU API: device, pipeline, vertex buffer, frame lifecycle (`gpu_begin_frame` / `gpu_end_frame`), `gpu_draw_triangle`.
- **`game.odin`** — Game state: `triangle_pos`, `camera_pos`, `proj_mat`, `view_proj_mat`, legacy `Ding`-based entity arrays. `game_init` builds the ortho projection; `game_loop` updates VP matrix and dispatches draw calls.
- **`math.odin`** — `Mat4` type + constructors: `mat4_identity`, `mat4_translate(Vec2)`, `mat4_ortho(l,r,b,t)`.
- **`ding.odin`** — `Vec2`, `Ding` struct (universal game object), movement, collision, `render_ding`.
- **`colors.odin`** — `Color` struct (RGBA u8) and named color constants.

### Key conventions
- `Ding` (German: "thing") is the central entity — everything interactive is a `Ding`.
- Global mutable state is intentional and pervasive (`dt_ms`, input flags, `view_proj_mat`).
- `dt_ms` is frame delta in **milliseconds**. For px/sec speeds: `speed * dt_ms / 1000`.
- World space is orthographic, centered: `(0,0)` = screen center, 1 unit = 1 pixel.
- MVP = `view_proj_mat * mat4_translate(world_pos)` — built per draw call in `gpu_draw_triangle`.
