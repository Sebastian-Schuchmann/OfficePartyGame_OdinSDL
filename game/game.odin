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

// scene holds every Ding that should be rendered each frame.
// Rule: if it appears on screen it must be a Ding in this array.
scene: [dynamic]engine.Ding

dinge:    [dynamic]^engine.Ding
og_dinge: [dynamic]engine.Ding

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

	// ---- Floor ----
	// 40×40 quad at y=0, drawn at world pos (0,-2,0). CCW from above = top face visible.
	floor_verts := []engine.Vertex {
		{pos = {-20, 0, -20}, col = {0.25, 0.22, 0.20, 1}},
		{pos = { 20, 0, -20}, col = {0.25, 0.22, 0.20, 1}},
		{pos = { 20, 0,  20}, col = {0.20, 0.18, 0.16, 1}},
		{pos = {-20, 0,  20}, col = {0.20, 0.18, 0.16, 1}},
	}
	append(&scene, engine.Ding{
		type = .PROP,
		pos3 = {0, -2, 0},
		mesh = engine.gpu_create_mesh(floor_verts, []u16{0, 1, 2, 0, 2, 3}),
	})

	// ---- Room (4 walls + ceiling) ----
	// 40×40×6 interior. All faces CCW from inside the room.
	wall_col    := [4]f32{0.82, 0.78, 0.74, 1}
	ceiling_col := [4]f32{0.92, 0.91, 0.90, 1}

	room_verts := []engine.Vertex {
		// Front wall (z=-20), normal +Z
		{pos = {-20, -2, -20}, col = wall_col}, // 0
		{pos = { 20, -2, -20}, col = wall_col}, // 1
		{pos = { 20,  4, -20}, col = wall_col}, // 2
		{pos = {-20,  4, -20}, col = wall_col}, // 3
		// Back wall (z=20), normal -Z
		{pos = {-20, -2,  20}, col = wall_col}, // 4
		{pos = { 20, -2,  20}, col = wall_col}, // 5
		{pos = { 20,  4,  20}, col = wall_col}, // 6
		{pos = {-20,  4,  20}, col = wall_col}, // 7
		// Left wall (x=-20), normal +X
		{pos = {-20, -2, -20}, col = wall_col}, // 8
		{pos = {-20, -2,  20}, col = wall_col}, // 9
		{pos = {-20,  4,  20}, col = wall_col}, // 10
		{pos = {-20,  4, -20}, col = wall_col}, // 11
		// Right wall (x=20), normal -X
		{pos = { 20, -2, -20}, col = wall_col}, // 12
		{pos = { 20, -2,  20}, col = wall_col}, // 13
		{pos = { 20,  4,  20}, col = wall_col}, // 14
		{pos = { 20,  4, -20}, col = wall_col}, // 15
		// Ceiling (y=4), normal -Y
		{pos = {-20, 4, -20}, col = ceiling_col}, // 16
		{pos = { 20, 4, -20}, col = ceiling_col}, // 17
		{pos = { 20, 4,  20}, col = ceiling_col}, // 18
		{pos = {-20, 4,  20}, col = ceiling_col}, // 19
	}
	room_indices := []u16 {
		0,  1,  2,   0,  2,  3,  // front  (+Z)
		4,  6,  5,   4,  7,  6,  // back   (-Z)
		8,  10, 9,   8,  11, 10, // left   (+X)
		12, 13, 14,  12, 14, 15, // right  (-X)
		16, 18, 17,  16, 19, 18, // ceil   (-Y)
	}
	append(&scene, engine.Ding{
		type = .PROP,
		mesh = engine.gpu_create_mesh(room_verts, room_indices),
	})

	// ---- Triangles ----
	// Shared mesh — CCW winding from the front face (camera looks at -Z).
	tri_verts := []engine.Vertex {
		{pos = { 0,  1, 0}, col = {1, 0, 0, 1}},
		{pos = {-1, -1, 0}, col = {0, 1, 0, 1}},
		{pos = { 1, -1, 0}, col = {0, 0, 1, 1}},
	}
	tri_mesh := engine.gpu_create_mesh(tri_verts, []u16{0, 1, 2})

	tri_positions := [][3]f32{
		{0, 0, -5}, {4, 0, -8}, {-4, 0, -8}, {2, 2, -12}, {-2, -2, -12},
	}
	for p in tri_positions {
		append(&scene, engine.Ding{
			type = .TRIANGLE,
			pos3 = p,
			mesh = tri_mesh,
		})
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
