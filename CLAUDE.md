# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```sh
odin run .        # build and run
odin build .      # build only
```

No test framework — verify behavior by running the game.

## Architecture
- Simple
- Hand Made Hero Style, fat structs, no oop

Single Odin package (`package main`) split across four files:

- **`main.odin`** — SDL3 window/renderer init, main loop, input polling, FPS debug overlay. Holds global state: `window`, `renderer`, `dt_ms`, and arrow-key booleans (`left_btn_down` etc.). Press `B` to toggle `DEBUG` mode.
- **`game.odin`** — Game state: a global `player` (`Ding`) and two dynamic arrays `dinge` (active entity pointers) and `og_dinge` (original state for reset). Implements `game_init`, `game_reset`, and `game_loop`.
- **`ding.odin`** — Core entity type. `Ding` is the universal game object (player, obstacle, collectable). Contains movement helpers (`move_ding`, `move_ding_inside_screen`), collision detection (`check_collision_ding` with shrink-rect padding), and `render_ding`. Movement is delta-time scaled via the global `dt_ms`.
- **`colors.odin`** — Defines the `Color` struct (RGBA u8) and all named color constants used across the project.

### Key conventions
- `Ding` (German: "thing") is the central entity struct — everything interactive is a `Ding`.
- Global mutable state is intentional and pervasive (renderer, dt_ms, input flags).
- `dt_ms` is the frame delta in milliseconds; multiply speed values by it for frame-rate-independent movement.
- Collision uses a shrunk rect (controlled by `COLLISION_PADDING`) to give forgiveness at edges.
