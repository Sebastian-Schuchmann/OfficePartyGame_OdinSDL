package main

import "core:fmt"
import strings "core:strings"
import sdl "vendor:sdl3"

WINDOW_WIDTH: i32 = 1600
WINDOW_HEIGHT: i32 = 1000

window: ^sdl.Window
renderer: ^sdl.Renderer
dt_ms: f64 = 0.0

left_btn_down: bool = false
right_btn_down: bool = false
up_btn_down: bool = false
down_btn_down: bool = false

player := Ding {
	pos    = Vec2{0, 0},
	color  = COLOR_DEEP_SAFFRON,
	width  = 60,
	height = 60,
	speed  = 1.0,
}

collectible := Ding {
	pos    = Vec2{700, 700},
	color  = COLOR_GREEN,
	width  = 30,
	height = 30,
}

dinge := []^Ding{&collectible, &player}

game_loop :: proc() {

	SPEED := player.speed
	left_right_speed := left_btn_down ? SPEED * -1 : right_btn_down ? SPEED : 0.0
	up_down_speed := up_btn_down ? SPEED * -1 : down_btn_down ? SPEED : 0.0

	move_ding(&player, Vec2{left_right_speed, up_down_speed})

	for ding in dinge {
		render_ding(renderer, ding^)
	}

	player_collides_with_collectible := check_collision_ding(&player, &collectible)

	if player_collides_with_collectible {
		set_ding_to_rnd_pos(&collectible)
	}

	draw_debug_text(renderer, Vec2{0, 30}, fmt.tprint("Collide", player_collides_with_collectible))
	draw_debug_text(renderer, Vec2{0, 40}, fmt.tprint("Player Pos", player.pos))
	draw_debug_text(renderer, Vec2{0, 50}, fmt.tprint("Collectible Pos", collectible.pos))
}

main :: proc() {

	success := sdl.Init({.VIDEO})


	ok := sdl.CreateWindowAndRenderer(
		"Title",
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.RESIZABLE},
		&window,
		&renderer,
	)

	sdl.SetRenderLogicalPresentation(renderer, WINDOW_WIDTH, WINDOW_HEIGHT, .LETTERBOX)
	sdl.SetRenderVSync(renderer, 0)

	tick := sdl.GetTicksNS()

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
			}
		}

		//CLEAR
		set_color(renderer, COLOR_VIVID_ROYAL)
		sdl.RenderClear(renderer)

		//MAIN LOGIC
		game_loop()

		draw_fps_counter(renderer, fps)
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
