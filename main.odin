package main

import "core:container/lru"
import "core:fmt"
import "core:math"
import "core:math/rand"
import strings "core:strings"
import sdl "vendor:sdl3"


WINDOW_WIDTH: i32 = 1600
WINDOW_HEIGHT: i32 = 1000
MAX_OBSTACLE_PAIRS :: 10
OBSTACLE_HEIGHT: f32 = 100.0

MAX_DIFFICULTY: f32 = 1.0
DIFFICULTY_INCREASE_PER_OBSTACLE: f32 = 0.01

GAP_SIZE_EASY: f32 = 1000
GAP_SIZE_HARD: f32 = 300

SPEED_EASY: f32 = 0.4
SPEED_HARD: f32 = 0.4

MIN_OVERLAP_EASY: f32 = 400
MIN_OVERLAP_HARD: f32 = 150


window: ^sdl.Window
renderer: ^sdl.Renderer
dt_ms: f64 = 0.0

left_btn_down: bool = false
right_btn_down: bool = false
up_btn_down: bool = false
down_btn_down: bool = false

previous_gap: Vec2

base_difficulty: f32 = 0.0
current_difficulty: f32 = 0.0


DingType :: enum {
	PLAYER,
	OBSTACLE,
	COLLECTABLE,
}


player := Ding {
	pos    = Vec2{cast(f32)WINDOW_WIDTH / 2 - 60, cast(f32)WINDOW_HEIGHT / 2 - 60 + 200},
	color  = COLOR_PLAYER,
	width  = 60,
	height = 60,
	speed  = 0.66,
	type   = DingType.PLAYER,
}

dinge: [dynamic]^Ding
og_dinge: [dynamic]Ding


game_loop :: proc() {

	SPEED := player.speed
	left_right_speed := left_btn_down ? SPEED * -1 : right_btn_down ? SPEED : 0.0
	up_down_speed := up_btn_down ? SPEED * -1 : down_btn_down ? SPEED : 0.0

	move_ding_inside_screen(&player, Vec2{left_right_speed, 0})

	spawn_new_obstacle := false

	for &ding in dinge {
		render_ding(renderer, ding^)

		if (ding.type == DingType.OBSTACLE) {
			if (ding.active) {
				move_ding(ding, Vec2{0.0, ding.speed})

				if (ding.pos.y > cast(f32)WINDOW_HEIGHT) {
					ding.active = false
					spawn_new_obstacle = true
				}

				obstacle_collides_with_player := check_collision_ding(&player, ding)
				if (obstacle_collides_with_player) {
					game_reset()
					return
				}
			}
		}
	}

	if (spawn_new_obstacle) {

		current_difficulty += DIFFICULTY_INCREASE_PER_OBSTACLE
		current_difficulty = math.clamp(current_difficulty, 0.0, 1.0)

		obstacleA: ^Ding
		obstacleB: ^Ding

		obstacleA_Set := false
		obstacleB_Set := false

		for &ding in dinge {
			if (obstacleA_Set && obstacleB_Set) {
				break
			}
			if (ding.type == DingType.OBSTACLE && !ding.active) {
				if (!obstacleA_Set) {
					obstacleA = ding
					obstacleA_Set = true
				} else {
					obstacleB = ding
					obstacleB_Set = true
				}
			}
		}

		set_obstacle_pair_based_on_difficulty(obstacleA, obstacleB, current_difficulty)
	}

	textPos: f32 = 50.0

	for ding in dinge {
		draw_debug_text(renderer, Vec2{0, textPos}, fmt.tprint("", ding.type, ding.pos))
		textPos += 10
	}

}


game_init :: proc() {


	//First obstacle


	OFFSET_BETWEEN_OBSTACLES: f32 = 110.0

	for i in 0 ..< MAX_OBSTACLE_PAIRS {
		l, r := create_obstacle_pair(600, 300, -100)
		set_obstacle_pair_based_on_difficulty(l, r, current_difficulty)

		l.pos.y = -100.0 - (cast(f32)i * OFFSET_BETWEEN_OBSTACLES)
		r.pos.y = -100.0 - (cast(f32)i * OFFSET_BETWEEN_OBSTACLES)

		append(&dinge, l)
		append(&dinge, r)
	}

	append(&dinge, &player)

	for ding in dinge {
		append(&og_dinge, ding^)
	}
}


set_obstacle_pair_based_on_difficulty :: proc(left: ^Ding, right: ^Ding, difficulty: f32) {
	gap_width := math.lerp(GAP_SIZE_EASY, GAP_SIZE_HARD, difficulty)

	min_x: f32 = 0
	max_x: f32 = cast(f32)WINDOW_WIDTH - gap_width

	MIN_OVERLAP := math.lerp(MIN_OVERLAP_EASY, MIN_OVERLAP_HARD, difficulty)

	// Constrain so the new gap overlaps the previous gap by at least MIN_OVERLAP,
	// ensuring the player can always reach the next gap.
	if previous_gap.y > 0 {
		prev_center := previous_gap.x
		prev_half := previous_gap.y / 2
		min_x = math.max(min_x, prev_center - prev_half + MIN_OVERLAP - gap_width / 2)
		max_x = math.min(max_x, prev_center + prev_half - MIN_OVERLAP + gap_width / 2)
	}

	rnd := rand.float32()
	gap_x := math.lerp(min_x, max_x, rnd)
	speed := math.lerp(SPEED_EASY, SPEED_HARD, difficulty)
	previous_gap = Vec2{gap_x, gap_width}
	set_obstacle_pair(left, right, gap_x, gap_width, speed)
}

set_obstacle_pair :: proc(left: ^Ding, right: ^Ding, gap_x: f32, gap_width: f32, speed: f32) {
	left.pos = Vec2{0, -100}
	left.width = gap_x
	left.speed = speed
	left.active = true
	right.pos = Vec2{gap_x + gap_width, -100}
	right.width = cast(f32)WINDOW_WIDTH - (gap_x + gap_width)
	right.speed = speed
	right.active = true

	color := random_color()
	right.color = color
	left.color = color
}

create_obstacle_pair :: proc(gap_x: f32, gap_width: f32, y: f32) -> (^Ding, ^Ding) {
	left := new(Ding)
	left^ = Ding {
		pos    = Vec2{0, y},
		color  = COLOR_MOLTEN_ORANGE,
		width  = gap_x,
		height = OBSTACLE_HEIGHT,
		speed  = 0.3,
		type   = DingType.OBSTACLE,
		active = false,
	}
	right := new(Ding)
	right^ = Ding {
		pos    = Vec2{gap_x + gap_width, y},
		color  = COLOR_MOLTEN_ORANGE,
		width  = cast(f32)WINDOW_WIDTH - (gap_x + gap_width),
		height = OBSTACLE_HEIGHT,
		speed  = 0.3,
		type   = DingType.OBSTACLE,
		active = false,
	}
	return left, right
}

game_reset :: proc() {
	current_difficulty = base_difficulty
	previous_gap = {}

	for i in 0 ..< len(dinge) {
		dinge[i]^ = og_dinge[i]
	}
}


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
				if ev.key.scancode == .B do DEBUG_DRAW_COLLISION = !DEBUG_DRAW_COLLISION
			}
		}

		//CLEAR
		set_color(renderer, COLOR_BACKGROUND)
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
