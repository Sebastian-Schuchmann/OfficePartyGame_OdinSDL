package game

import "core:math"
import engine "../engine"

GRAVITY     :: f32(-14.0)
FLOOR_Y     :: f32(-2.0)  // world-space y of the floor surface
EYE_HEIGHT  :: f32(1.7)
JUMP_SPEED  :: f32(6.0)

// Minimum camera y: standing eye level above the floor
CAMERA_MIN_Y :: FLOOR_Y + EYE_HEIGHT

camera_update :: proc(input: Input) {
	dt := f32(input.dt_ms) / 1000

	// --- Look ---
	if input.mouse_locked {
		camera.yaw   += input.mouse_dx * camera.mouse_sensitivity
		camera.pitch += input.mouse_dy * camera.mouse_sensitivity
	}
	camera.pitch = clamp(camera.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)

	cy := math.cos(camera.yaw)
	sy := math.sin(camera.yaw)

	// Horizontal-only direction vectors (pitch doesn't affect movement)
	fwd   := engine.Vec3{sy, 0, -cy}
	right := engine.Vec3{cy, 0,  sy}

	// --- Horizontal movement ---
	speed := camera.speed * dt
	if input.w do camera.pos3 += fwd   * speed
	if input.s do camera.pos3 -= fwd   * speed
	if input.d do camera.pos3 += right * speed
	if input.a do camera.pos3 -= right * speed

	// --- Gravity + jump ---
	grounded := camera.pos3.y <= CAMERA_MIN_Y + 0.01
	camera.vel3.y += GRAVITY * dt

	if input.q && grounded {
		camera.vel3.y = JUMP_SPEED
	}

	camera.pos3.y += camera.vel3.y * dt

	if camera.pos3.y < CAMERA_MIN_Y {
		camera.pos3.y = CAMERA_MIN_Y
		camera.vel3.y = 0
	}

	view_proj_mat = proj_mat * engine.mat4_view(camera.pos3, camera.yaw, camera.pitch)
}
