package main
import "core:math"
import "core:math/rand"
import sdl "vendor:sdl3"

Vec2 :: struct {
	x: f32,
	y: f32,
}

Ding :: struct {
	pos:    Vec2,
	color:  Color,
	width:  f32,
	height: f32,
	speed:  f32,
}

get_f_rect_from_ding :: proc(ding: ^Ding) -> sdl.FRect {
	rect := sdl.FRect{ding.pos.x, ding.pos.y, ding.width, ding.height}
	return rect
}

render_ding :: proc(renderer: ^sdl.Renderer, ding: Ding) {
	set_color(renderer, ding.color)
	rect := sdl.FRect{ding.pos.x, ding.pos.y, ding.width, ding.height}
	sdl.RenderFillRect(renderer, &rect)
}

move_ding :: proc(ding: ^Ding, dir: Vec2) {
	ding.pos.x += dir.x
	ding.pos.y += dir.y
}

set_ding_to_rnd_pos :: proc(ding: ^Ding) {
	x := rand.float32_range(0, cast(f32)WINDOW_WIDTH)
	y := rand.float32_range(0, cast(f32)WINDOW_HEIGHT)

	ding.pos = Vec2{x, y}
}

check_collision_ding :: proc(a: ^Ding, b: ^Ding) -> bool {
	rect_a := get_f_rect_from_ding(a)
	rect_b := get_f_rect_from_ding(b)
	collide := sdl.HasRectIntersectionFloat(rect_a, rect_b)
	return collide
}
