package main

import "core:math"

proj_mat:      Mat4
view_proj_mat: Mat4

player := Ding{
	pos    = Vec2{cast(f32)WINDOW_WIDTH / 2 - 60, cast(f32)WINDOW_HEIGHT / 2 - 60 + 200},
	color  = COLOR_PLAYER,
	width  = 60,
	height = 60,
	speed  = 0.66,
	type   = DingType.PLAYER,
}

camera := Ding{
	type = DingType.CAMERA,
}

triangle := Ding{
	pos3 = Vec3{0, 0, -5},
	type = DingType.TRIANGLE,
}

dinge: [dynamic]^Ding
og_dinge: [dynamic]Ding

game_init :: proc() {
	append(&dinge, &player)

	for ding in dinge {
		append(&og_dinge, ding^)
	}

	proj_mat = mat4_perspective(math.PI / 3, f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT), 0.1, 1000)
}

game_reset :: proc() {
	for i in 0 ..< len(dinge) {
		dinge[i]^ = og_dinge[i]
	}
}

game_loop :: proc() {
	SPEED:             f32 = 5       // units per second
	MOUSE_SENSITIVITY: f32 = 0.002   // radians per pixel

	camera.yaw   += mouse_dx * MOUSE_SENSITIVITY
	camera.pitch += mouse_dy * MOUSE_SENSITIVITY
	camera.pitch  = clamp(camera.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)

	cx := math.cos(camera.pitch)
	sx := math.sin(camera.pitch)
	cy := math.cos(camera.yaw)
	sy := math.sin(camera.yaw)

	fwd   := Vec3{sy * cx, -sx, -cy * cx}
	right := Vec3{cy, 0, sy}

	speed := SPEED * f32(dt_ms) / 1000
	if w_key_down do camera.pos3 += fwd   * speed
	if s_key_down do camera.pos3 -= fwd   * speed
	if d_key_down do camera.pos3 += right * speed
	if a_key_down do camera.pos3 -= right * speed
	if e_key_down do camera.pos3.y += speed
	if q_key_down do camera.pos3.y -= speed

	p := camera.pos3
	view_mat := Mat4{
		cy,       0,   sy,      -(cy * p.x + sy * p.z),
		sy * sx,  cx,  -cy * sx, -(sy * sx * p.x + cx * p.y - cy * sx * p.z),
		-sy * cx, sx,  cy * cx,  sy * cx * p.x - sx * p.y - cy * cx * p.z,
		0,        0,   0,       1,
	}

	view_proj_mat = proj_mat * view_mat

	gpu_draw_triangle(triangle.pos3)
}
