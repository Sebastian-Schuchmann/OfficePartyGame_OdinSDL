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
room_mesh:  engine.GpuMesh

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

	// Floor quad: 40x40 at y=0, drawn at y=-2.
	// CCW from above → top face is front face.
	floor_verts := []engine.Vertex {
		{pos = {-20, 0, -20}, col = {0.25, 0.22, 0.20, 1}},
		{pos = { 20, 0, -20}, col = {0.25, 0.22, 0.20, 1}},
		{pos = { 20, 0,  20}, col = {0.20, 0.18, 0.16, 1}},
		{pos = {-20, 0,  20}, col = {0.20, 0.18, 0.16, 1}},
	}
	floor_mesh = engine.gpu_create_mesh(floor_verts, []u16{0, 1, 2, 0, 2, 3})

	// Room: 40×6 interior (x±20, z±20, y -2..4).
	// All faces have CCW winding when viewed from INSIDE the room.
	//
	// Wall layout (viewed from above, camera inside):
	//   front  (z=-20): normal +Z  → CCW in XY plane  → indices: 0,1,2  0,2,3
	//   back   (z= 20): normal -Z  → CW  in XY plane  → indices: 0,2,1  0,3,2
	//   left   (x=-20): normal +X  → reversed z-order → indices: 0,2,1  0,3,2
	//   right  (x= 20): normal -X  → normal z-order   → indices: 0,1,2  0,2,3
	//   ceiling(y=  4): normal -Y  → CCW in XZ plane  → indices: 0,1,2  0,2,3

	wall_col   := [4]f32{0.82, 0.78, 0.74, 1}
	ceiling_col := [4]f32{0.92, 0.91, 0.90, 1}

	room_verts := []engine.Vertex {
		// Front wall (z=-20), normal +Z: CCW order 0,1,2 / 0,2,3
		{pos = {-20, -2, -20}, col = wall_col}, // 0
		{pos = { 20, -2, -20}, col = wall_col}, // 1
		{pos = { 20,  4, -20}, col = wall_col}, // 2
		{pos = {-20,  4, -20}, col = wall_col}, // 3

		// Back wall (z=20), normal -Z: reversed 0,2,1 / 0,3,2
		{pos = {-20, -2,  20}, col = wall_col}, // 4
		{pos = { 20, -2,  20}, col = wall_col}, // 5
		{pos = { 20,  4,  20}, col = wall_col}, // 6
		{pos = {-20,  4,  20}, col = wall_col}, // 7

		// Left wall (x=-20), normal +X: order 0,2,1 / 0,3,2
		{pos = {-20, -2, -20}, col = wall_col}, // 8
		{pos = {-20, -2,  20}, col = wall_col}, // 9
		{pos = {-20,  4,  20}, col = wall_col}, // 10
		{pos = {-20,  4, -20}, col = wall_col}, // 11

		// Right wall (x=20), normal -X: order 0,1,2 / 0,2,3
		{pos = { 20, -2, -20}, col = wall_col}, // 12
		{pos = { 20, -2,  20}, col = wall_col}, // 13
		{pos = { 20,  4,  20}, col = wall_col}, // 14
		{pos = { 20,  4, -20}, col = wall_col}, // 15

		// Ceiling (y=4), normal -Y: order 0,1,2 / 0,2,3
		{pos = {-20, 4, -20}, col = ceiling_col}, // 16
		{pos = { 20, 4, -20}, col = ceiling_col}, // 17
		{pos = { 20, 4,  20}, col = ceiling_col}, // 18
		{pos = {-20, 4,  20}, col = ceiling_col}, // 19
	}

	room_indices := []u16 {
		// Front wall (+Z normal)
		0, 1, 2,   0, 2, 3,
		// Back wall (-Z normal)
		4, 6, 5,   4, 7, 6,
		// Left wall (+X normal)
		8, 10, 9,  8, 11, 10,
		// Right wall (-X normal)
		12, 13, 14,  12, 14, 15,
		// Ceiling (-Y normal)
		16, 18, 17,  16, 19, 18,
	}
	room_mesh = engine.gpu_create_mesh(room_verts, room_indices)
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
	engine.gpu_draw_mesh(room_mesh,  {0,  0, 0}, view_proj_mat)

	for t in triangles {
		engine.gpu_draw_triangle(t.pos3, view_proj_mat)
	}
}
