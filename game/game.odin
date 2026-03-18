package game

import engine "../engine"
import "core:math"

Input :: struct {
	dt_ms:              f64,
	w, a, s, d, q, e:   bool,
	mouse_dx, mouse_dy: f32,
	mouse_locked:       bool,
}

proj_mat: engine.Mat4
view_proj_mat: engine.Mat4

camera := engine.Ding {
	type              = engine.DingType.CAMERA,
	fov               = math.PI / 3,
	speed             = 5,
	mouse_sensitivity = 0.002,
}

// scene holds every Ding that should be rendered each frame.
// Rule: if it appears on screen it must be a Ding (Like an Entity) in this array.
scene: [dynamic]engine.Ding

dinge: [dynamic]^engine.Ding
og_dinge: [dynamic]engine.Ding

game_init :: proc(win_w, win_h: i32) {
	for ding in dinge {
		append(&og_dinge, ding^)
	}

	proj_mat = engine.mat4_perspective(camera.fov, f32(win_w) / f32(win_h), 0.1, 1000)

	init_materials()
	init_meshes()

	// ---- Triangles ----
	tri_mats := [5]^engine.Material{mat_red, mat_green, mat_blue, mat_red, mat_blue}
	tri_positions := [][3]f32{{0, 0, -5}, {4, 0, -8}, {-4, 0, -8}, {2, 2, -12}, {-2, -2, -12}}
	for p, i in tri_positions {
		append(
			&scene,
			engine.Ding{type = .TRIANGLE, pos3 = p, mesh = tri_mesh, material = tri_mats[i]},
		)
	}
}

on_resize :: proc(win_w, win_h: i32) {
	proj_mat = engine.mat4_perspective(camera.fov, f32(win_w) / f32(win_h), 0.1, 1000)
}

game_reset :: proc() {
	for i in 0 ..< len(dinge) {
		dinge[i]^ = og_dinge[i]
	}
}

game_loop :: proc(input: Input) {
	camera_update(input)

	for d in scene {
		engine.gpu_draw_ding(d, view_proj_mat)
	}
}
