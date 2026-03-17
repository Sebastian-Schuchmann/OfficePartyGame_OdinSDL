package game

import engine "../engine"
import "core:math"

Input :: struct {
	dt_ms:              f64,
	w, a, s, d, q, e:   bool,
	mouse_dx, mouse_dy: f32,
	mouse_locked:       bool,
}

proj_mat:      engine.Mat4
view_proj_mat: engine.Mat4

player: engine.Ding
camera := engine.Ding {
	type              = engine.DingType.CAMERA,
	fov               = math.PI / 3,
	speed             = 5,
	mouse_sensitivity = 0.002,
}

triangles := [5]engine.Ding {
	{pos3 = engine.Vec3{0, 0, -5},    type = engine.DingType.TRIANGLE},
	{pos3 = engine.Vec3{4, 0, -8},    type = engine.DingType.TRIANGLE},
	{pos3 = engine.Vec3{-4, 0, -8},   type = engine.DingType.TRIANGLE},
	{pos3 = engine.Vec3{2, 2, -12},   type = engine.DingType.TRIANGLE},
	{pos3 = engine.Vec3{-2, -2, -12}, type = engine.DingType.TRIANGLE},
}

dinge:    [dynamic]^engine.Ding
og_dinge: [dynamic]engine.Ding

floor_mesh: engine.GpuMesh

game_init :: proc(win_w, win_h: i32) {
	player = engine.Ding {
		pos    = engine.Vec2{f32(win_w) / 2 - 60, f32(win_h) / 2 - 60 + 200},
		color  = engine.COLOR_PLAYER,
		width  = 60,
		height = 60,
		speed  = 0.66,
		type   = engine.DingType.PLAYER,
	}

	append(&dinge, &player)
	for ding in dinge {
		append(&og_dinge, ding^)
	}

	proj_mat = engine.mat4_perspective(camera.fov, f32(win_w) / f32(win_h), 0.1, 1000)

	// Build floor quad: 40x40 units, sitting at y=0.
	// Draw call translates it to y=-2 so it sits below the origin triangles.
	// Vertices are CCW from above so backface culling keeps the top face.
	floor_verts := []engine.Vertex {
		{pos = {-20, 0, -20}, col = {0.25, 0.22, 0.20, 1}},
		{pos = { 20, 0, -20}, col = {0.25, 0.22, 0.20, 1}},
		{pos = { 20, 0,  20}, col = {0.20, 0.18, 0.16, 1}},
		{pos = {-20, 0,  20}, col = {0.20, 0.18, 0.16, 1}},
	}
	floor_indices := []u16{0, 1, 2, 0, 2, 3}
	floor_mesh = engine.gpu_create_mesh(floor_verts, floor_indices)
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

	engine.gpu_draw_mesh(floor_mesh, {0, -2, 0}, view_proj_mat)

	for t in triangles {
		engine.gpu_draw_triangle(t.pos3, view_proj_mat)
	}
}
