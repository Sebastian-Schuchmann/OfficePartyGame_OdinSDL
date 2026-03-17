package engine

import "core:math"
import "core:math/rand"

DingType :: enum {
	PLAYER,
	OBSTACLE,
	COLLECTABLE,
	CAMERA,
	TRIANGLE,
	PROP,       // static scene geometry (floor, walls, furniture, etc.)
}

Ding :: struct {
	// 2D
	pos:               Vec2,
	color:             Color,
	width:             f32,
	height:            f32,
	// 3D
	pos3:              Vec3,
	vel3:              Vec3,
	yaw:               f32,
	pitch:             f32,
	roll:              f32,
	// Camera
	fov:               f32,
	mouse_sensitivity: f32,
	// 3D mesh (zero if unused — Ding is drawn via gpu_draw_ding only if mesh.vertex_buf != nil)
	mesh:     GpuMesh,
	material: ^Material, // nil = skip draw
	// Shared
	speed:             f32,
	type:              DingType,
	active:            bool,
}

move_ding :: proc(ding: ^Ding, dir: Vec2, dt_ms: f64) {
	ding.pos.x += dir.x * f32(dt_ms)
	ding.pos.y += dir.y * f32(dt_ms)
}

move_ding_inside_screen :: proc(ding: ^Ding, dir: Vec2, dt_ms: f64, win_w, win_h: i32) {
	max_pos_x := f32(win_w) - ding.width
	max_pos_y := f32(win_h) - ding.height

	move_ding(ding, dir, dt_ms)

	ding.pos.x = math.clamp(ding.pos.x, 0, max_pos_x)
	ding.pos.y = math.clamp(ding.pos.y, 0, max_pos_y)
}

set_ding_to_rnd_pos :: proc(ding: ^Ding, win_w, win_h: i32) {
	x := rand.float32_range(0, f32(win_w))
	y := rand.float32_range(0, f32(win_h))
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
	return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y
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
