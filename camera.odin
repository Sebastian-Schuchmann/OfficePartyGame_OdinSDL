package main

import "core:math"

camera_update :: proc() {
	if mouse_locked {
		camera.yaw   += mouse_dx * camera.mouse_sensitivity
		camera.pitch += mouse_dy * camera.mouse_sensitivity
	}
	camera.pitch  = clamp(camera.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)

	cx := math.cos(camera.pitch)
	sx := math.sin(camera.pitch)
	cy := math.cos(camera.yaw)
	sy := math.sin(camera.yaw)

	fwd   := Vec3{sy * cx, -sx, -cy * cx}
	right := Vec3{cy, 0, sy}

	speed := camera.speed * f32(dt_ms) / 1000
	if w_key_down do camera.pos3 += fwd   * speed
	if s_key_down do camera.pos3 -= fwd   * speed
	if d_key_down do camera.pos3 += right * speed
	if a_key_down do camera.pos3 -= right * speed
	if e_key_down do camera.pos3.y += speed
	if q_key_down do camera.pos3.y -= speed

	view_proj_mat = proj_mat * mat4_view(camera.pos3, camera.yaw, camera.pitch)
}
