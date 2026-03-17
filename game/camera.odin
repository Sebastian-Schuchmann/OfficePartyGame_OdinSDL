package game

import engine "../engine"
import "core:math"

camera_update :: proc(input: Input) {
	if input.mouse_locked {
		camera.yaw += input.mouse_dx * camera.mouse_sensitivity
		camera.pitch += input.mouse_dy * camera.mouse_sensitivity
	}
	camera.pitch = clamp(camera.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)

	cx := math.cos(camera.pitch)
	sx := math.sin(camera.pitch)
	cy := math.cos(camera.yaw)
	sy := math.sin(camera.yaw)

	fwd := engine.Vec3{sy * cx, -sx, -cy * cx}
	right := engine.Vec3{cy, 0, sy}

	speed := camera.speed * f32(input.dt_ms) / 1000
	if input.w do camera.pos3 += fwd * speed
	if input.s do camera.pos3 -= fwd * speed
	if input.d do camera.pos3 += right * speed
	if input.a do camera.pos3 -= right * speed
	if input.e do camera.pos3.y += speed
	if input.q do camera.pos3.y -= speed

	view_proj_mat = proj_mat * engine.mat4_view(camera.pos3, camera.yaw, camera.pitch)
}
