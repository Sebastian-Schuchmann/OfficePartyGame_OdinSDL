package main

import "core:container/lru"
import "core:fmt"
import "core:math"
import "core:math/rand"
import strings "core:strings"
import sdl "vendor:sdl3"

DEBUG: bool = false

WINDOW_WIDTH: i32 = 1600
WINDOW_HEIGHT: i32 = 1000

window: ^sdl.Window
renderer: ^sdl.Renderer
dt_ms: f64 = 0.0

left_btn_down: bool = false
right_btn_down: bool = false
up_btn_down: bool = false
down_btn_down: bool = false

main :: proc() {

	success := sdl.Init({.VIDEO})

	ok := sdl.CreateWindowAndRenderer(
		"Office Party Game",
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.RESIZABLE},
		&window,
		&renderer,
	)

	sdl.SetRenderLogicalPresentation(renderer, WINDOW_WIDTH, WINDOW_HEIGHT, .LETTERBOX)
	sdl.SetRenderVSync(renderer, 1)

	tick := sdl.GetTicksNS()

	game_init()

	main_loop: for {
		ev: sdl.Event

		dt := sdl.GetTicksNS() - tick
		tick = sdl.GetTicksNS()
		dt_ms = cast(f64)dt / 1e6
		fps := 1000.0 / dt_ms

		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				break main_loop
			case .KEY_DOWN:
				if ev.key.scancode == .ESCAPE do break main_loop
				if ev.key.scancode == .LEFT do left_btn_down = true
				if ev.key.scancode == .RIGHT do right_btn_down = true
				if ev.key.scancode == .UP do up_btn_down = true
				if ev.key.scancode == .DOWN do down_btn_down = true
			case .KEY_UP:
				if ev.key.scancode == .LEFT do left_btn_down = false
				if ev.key.scancode == .RIGHT do right_btn_down = false
				if ev.key.scancode == .UP do up_btn_down = false
				if ev.key.scancode == .DOWN do down_btn_down = false
				if ev.key.scancode == .B do DEBUG = !DEBUG
			}
		}

		//CLEAR
		set_color(renderer, COLOR_BACKGROUND)
		sdl.RenderClear(renderer)

		//MAIN LOGIC
		game_loop()

		if DEBUG {
			draw_fps_counter(renderer, fps)
		}
		sdl.RenderPresent(renderer)
	}
}

draw_debug_text :: proc(renderer: ^sdl.Renderer, pos: Vec2, text: string) {
	set_color(renderer, COLOR_WHITE)
	sdl.RenderDebugText(renderer, pos.x, pos.y, strings.clone_to_cstring(text))
}

draw_fps_counter :: proc(renderer: ^sdl.Renderer, fps: f64) {
	set_color(renderer, COLOR_WHITE)
	sdl.RenderDebugText(renderer, 0, 0, fmt.ctprintf("FPS:%d (%f)", cast(i64)fps, dt_ms))
	sdl.RenderDebugText(renderer, 0, 10, fmt.ctprintf("L:%v R:%v", left_btn_down, right_btn_down))
}

set_color :: proc(renderer: ^sdl.Renderer, color: Color) {
	sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)
}
