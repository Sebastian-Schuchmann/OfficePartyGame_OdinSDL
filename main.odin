package main

import "core:fmt"
import sdl "vendor:sdl3"

DEBUG: bool = false

WINDOW_WIDTH:  i32 = 1600
WINDOW_HEIGHT: i32 = 1000

window: ^sdl.Window
dt_ms:  f64 = 0.0

left_btn_down:  bool = false
right_btn_down: bool = false
up_btn_down:    bool = false
down_btn_down:  bool = false

main :: proc() {
	_ = sdl.Init({.VIDEO})

	window = sdl.CreateWindow("Office Party Game", WINDOW_WIDTH, WINDOW_HEIGHT, {.RESIZABLE})

	gpu_init()

	tick := sdl.GetTicksNS()

	game_init()

	main_loop: for {
		ev: sdl.Event

		dt    := sdl.GetTicksNS() - tick
		tick   = sdl.GetTicksNS()
		dt_ms  = cast(f64)dt / 1e6
		fps   := 1000.0 / dt_ms

		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				break main_loop
			case .KEY_DOWN:
				if ev.key.scancode == .ESCAPE do break main_loop
				if ev.key.scancode == .LEFT   do left_btn_down = true
				if ev.key.scancode == .RIGHT  do right_btn_down = true
				if ev.key.scancode == .UP     do up_btn_down = true
				if ev.key.scancode == .DOWN   do down_btn_down = true
			case .KEY_UP:
				if ev.key.scancode == .LEFT   do left_btn_down = false
				if ev.key.scancode == .RIGHT  do right_btn_down = false
				if ev.key.scancode == .UP     do up_btn_down = false
				if ev.key.scancode == .DOWN   do down_btn_down = false
				if ev.key.scancode == .B      do DEBUG = !DEBUG
			}
		}

		if gpu_begin_frame() {
			game_loop()
			gpu_end_frame()
		}

		if DEBUG {
			fmt.println("FPS:", cast(i64)fps, "dt_ms:", dt_ms)
		}
	}
}
