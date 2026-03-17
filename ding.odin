package main
import "core:math"
import "core:math/rand"
import sdl "vendor:sdl3"

Vec2 :: struct {
	x: f32,
	y: f32,
}

DingType :: enum {
	PLAYER,
	OBSTACLE,
	COLLECTABLE,
}

Ding :: struct {
	pos:    Vec2,
	color:  Color,
	width:  f32,
	height: f32,
	speed:  f32,
	type:   DingType,
	active: bool,
}

get_f_rect_from_ding :: proc(ding: ^Ding) -> sdl.FRect {
	rect := sdl.FRect{ding.pos.x, ding.pos.y, ding.width, ding.height}
	return rect
}

render_ding :: proc(renderer: ^sdl.Renderer, ding: Ding) {
	set_color(renderer, ding.color)
	rect := sdl.FRect{ding.pos.x, ding.pos.y, ding.width, ding.height}
	sdl.RenderFillRect(renderer, &rect)

	if DEBUG {
		collision_rect := shrink_rect(rect, COLLISION_PADDING)
		set_color(renderer, COLOR_RED)
		sdl.RenderRect(renderer, &collision_rect)
	}
}

move_ding :: proc(ding: ^Ding, dir: Vec2) {
	ding.pos.x += dir.x * cast(f32)dt_ms
	ding.pos.y += dir.y * cast(f32)dt_ms
}

move_ding_inside_screen :: proc(ding: ^Ding, dir: Vec2) {

	maxPosX := cast(f32)WINDOW_WIDTH - ding.width
	maxPosY := cast(f32)WINDOW_HEIGHT - ding.height

	move_ding(ding, dir)

	ding.pos.x = math.clamp(ding.pos.x, 0, maxPosX)
	ding.pos.y = math.clamp(ding.pos.y, 0, maxPosY)
}

set_ding_to_rnd_pos :: proc(ding: ^Ding) {
	x := rand.float32_range(0, cast(f32)WINDOW_WIDTH)
	y := rand.float32_range(0, cast(f32)WINDOW_HEIGHT)

	ding.pos = Vec2{x, y}
}

COLLISION_PADDING: f32 = 0.05

shrink_rect :: proc(rect: sdl.FRect, padding: f32) -> sdl.FRect {
	d := math.min(rect.w, rect.h) * padding
	return sdl.FRect{rect.x + d, rect.y + d, rect.w - d * 2, rect.h - d * 2}
}

check_collision_ding :: proc(a: ^Ding, b: ^Ding) -> bool {
	rect_a := shrink_rect(get_f_rect_from_ding(a), COLLISION_PADDING)
	rect_b := shrink_rect(get_f_rect_from_ding(b), COLLISION_PADDING)
	return sdl.HasRectIntersectionFloat(rect_a, rect_b)
}
