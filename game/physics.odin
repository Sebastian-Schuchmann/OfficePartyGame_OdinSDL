package game

// Grounded physics — reserved for future use (M6 re-integration).
//
// To restore: replace camera_update in camera.odin with camera_update_grounded below.
// Also change Q binding in main.odin (Q = jump, E = unused or crouch).

// GRAVITY     :: f32(-14.0)
// FLOOR_Y     :: f32(-2.0)    // world-space y of the floor surface
// EYE_HEIGHT  :: f32(1.7)     // camera eye level above the floor
// JUMP_SPEED  :: f32(6.0)
// CAMERA_MIN_Y :: FLOOR_Y + EYE_HEIGHT

// camera_update_grounded :: proc(input: Input) {
// 	dt := f32(input.dt_ms) / 1000
//
// 	if input.mouse_locked {
// 		camera.yaw   += input.mouse_dx * camera.mouse_sensitivity
// 		camera.pitch += input.mouse_dy * camera.mouse_sensitivity
// 	}
// 	camera.pitch = clamp(camera.pitch, -math.PI / 2 + 0.01, math.PI / 2 - 0.01)
//
// 	cy := math.cos(camera.yaw)
// 	sy := math.sin(camera.yaw)
//
// 	// Horizontal-only movement — pitch does not affect walk direction
// 	fwd   := engine.Vec3{sy, 0, -cy}
// 	right := engine.Vec3{cy, 0,  sy}
//
// 	speed := camera.speed * dt
// 	if input.w do camera.pos3 += fwd   * speed
// 	if input.s do camera.pos3 -= fwd   * speed
// 	if input.d do camera.pos3 += right * speed
// 	if input.a do camera.pos3 -= right * speed
//
// 	grounded := camera.pos3.y <= CAMERA_MIN_Y + 0.01
// 	camera.vel3.y += GRAVITY * dt
//
// 	if input.q && grounded {
// 		camera.vel3.y = JUMP_SPEED
// 	}
//
// 	camera.pos3.y += camera.vel3.y * dt
//
// 	if camera.pos3.y < CAMERA_MIN_Y {
// 		camera.pos3.y = CAMERA_MIN_Y
// 		camera.vel3.y = 0
// 	}
//
// 	view_proj_mat = proj_mat * engine.mat4_view(camera.pos3, camera.yaw, camera.pitch)
// }
