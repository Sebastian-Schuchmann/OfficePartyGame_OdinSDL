package main

import "core:fmt"
import sdl "vendor:sdl3"

DEBUG: bool = false

WINDOW_WIDTH:  i32 = 1600
WINDOW_HEIGHT: i32 = 1000

window: ^sdl.Window
dt_ms:  f64 = 0.0

w_key_down: bool
a_key_down: bool
s_key_down: bool
d_key_down: bool
q_key_down: bool
e_key_down: bool

mouse_dx: f32
mouse_dy: f32

main :: proc() {
	_ = sdl.Init({.VIDEO})

	window = sdl.CreateWindow("Office Party Game", WINDOW_WIDTH, WINDOW_HEIGHT, {.RESIZABLE})

	gpu_init()

	tick := sdl.GetTicksNS()

	game_init()

	_ = sdl.SetWindowRelativeMouseMode(window, true)

	main_loop: for {
		ev: sdl.Event

		dt    := sdl.GetTicksNS() - tick
		tick   = sdl.GetTicksNS()
		dt_ms  = cast(f64)dt / 1e6
		fps   := 1000.0 / dt_ms

		mouse_dx = 0
		mouse_dy = 0

		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
			case .QUIT:
				break main_loop
			case .KEY_DOWN:
				if ev.key.scancode == .ESCAPE do break main_loop
				if ev.key.scancode == .W do w_key_down = true
				if ev.key.scancode == .A do a_key_down = true
				if ev.key.scancode == .S do s_key_down = true
				if ev.key.scancode == .D do d_key_down = true
				if ev.key.scancode == .Q do q_key_down = true
				if ev.key.scancode == .E do e_key_down = true
			case .KEY_UP:
				if ev.key.scancode == .W do w_key_down = false
				if ev.key.scancode == .A do a_key_down = false
				if ev.key.scancode == .S do s_key_down = false
				if ev.key.scancode == .D do d_key_down = false
				if ev.key.scancode == .Q do q_key_down = false
				if ev.key.scancode == .E do e_key_down = false
				if ev.key.scancode == .B do DEBUG = !DEBUG
			case .MOUSE_MOTION:
				mouse_dx += ev.motion.xrel
				mouse_dy += ev.motion.yrel
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
