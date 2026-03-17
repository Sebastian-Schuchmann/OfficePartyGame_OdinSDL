package main
import "core:math"
import "core:math/rand"

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


Rect2 :: struct {
	x, y, w, h: f32,
}

get_rect_from_ding :: proc(ding: ^Ding) -> Rect2 {
	return Rect2{ding.pos.x, ding.pos.y, ding.width, ding.height}
}

rects_overlap :: proc(a, b: Rect2) -> bool {
	return a.x < b.x + b.w && a.x + a.w > b.x &&
	       a.y < b.y + b.h && a.y + a.h > b.y
}

shrink_rect2 :: proc(r: Rect2, padding: f32) -> Rect2 {
	d := math.min(r.w, r.h) * padding
	return Rect2{r.x + d, r.y + d, r.w - d * 2, r.h - d * 2}
}

check_collision_ding :: proc(a: ^Ding, b: ^Ding) -> bool {
	rect_a := shrink_rect2(get_rect_from_ding(a), COLLISION_PADDING)
	rect_b := shrink_rect2(get_rect_from_ding(b), COLLISION_PADDING)
	return rects_overlap(rect_a, rect_b)
}
