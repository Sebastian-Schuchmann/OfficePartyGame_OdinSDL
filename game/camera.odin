package game

import "core:math"
import engine "../engine"

GAMEPAD_LOOK_SENSITIVITY :: f32(2.5) // radians per second for right stick

camera_update :: proc(input: Input) {
	gp := input.gamepad
	dt := f32(input.dt_ms) / 1000

	// Look: mouse (when locked) + right stick
	if input.mouse_locked {
		camera.yaw   += input.mouse_dx * camera.mouse_sensitivity
		camera.pitch += input.mouse_dy * camera.mouse_sensitivity
	}
	camera.yaw   += gp.right_x * GAMEPAD_LOOK_SENSITIVITY * dt
	camera.pitch += gp.right_y * GAMEPAD_LOOK_SENSITIVITY * dt
	camera.pitch = clamp(camera.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)

	cx := math.cos(camera.pitch)
	sx := math.sin(camera.pitch)
	cy := math.cos(camera.yaw)
	sy := math.sin(camera.yaw)

	fwd   := engine.Vec3{sy * cx, -sx, -cy * cx}
	right := engine.Vec3{cy, 0, sy}

	speed := camera.speed * dt

	// Move: WASD + left stick (contributions are summed then clamped to speed)
	// Left stick Y: up = negative Y on stick = forward
	fwd_axis   := clamp(-gp.left_y, -1, 1)
	right_axis := clamp( gp.left_x, -1, 1)
	if input.w do fwd_axis   = max(fwd_axis,   1)
	if input.s do fwd_axis   = min(fwd_axis,  -1)
	if input.d do right_axis = max(right_axis,  1)
	if input.a do right_axis = min(right_axis, -1)

	camera.pos3 += fwd   * speed * fwd_axis
	camera.pos3 += right * speed * right_axis
	if input.e || gp.y do camera.pos3.y += speed
	if input.q || gp.a do camera.pos3.y -= speed

	view_proj_mat     = proj_mat * engine.mat4_view(camera.pos3, camera.yaw, camera.pitch)
	engine.gpu_cam_pos = camera.pos3
}
