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
camera := engine.Ding{
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

// Fixed-size material pool — avoids GC pressure.
// All Materials are allocated here; Ding.material points into this array.
// Fat struct: all shader properties live in Material regardless of shader used.
MAX_MATERIALS :: 64
materials:      [MAX_MATERIALS]engine.Material
material_count: int

alloc_material :: proc() -> ^engine.Material {
	assert(material_count < MAX_MATERIALS, "material pool exhausted")
	m := &materials[material_count]
	material_count += 1
	return m
}

game_init :: proc(win_w, win_h: i32) {
	player = engine.Ding{
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

	// Directional light — warm overhead-ish light, slight ambient
	engine.gpu_dir_light = engine.DirLight{
		direction = {0.5, -1.0, -0.3},
		color     = {1.0, 0.95, 0.88},
		ambient   = 0.18,
	}

	// ---- Floor ----
	floor_mat := alloc_material()
	floor_mat^ = engine.Material{shader = .LIT, color = {0.23, 0.20, 0.18, 1}, specular = 0.05, shininess = 16}

	floor_verts := []engine.Vertex{
		{pos = {-20, 0, -20}, normal = {0, 1, 0}},
		{pos = { 20, 0, -20}, normal = {0, 1, 0}},
		{pos = { 20, 0,  20}, normal = {0, 1, 0}},
		{pos = {-20, 0,  20}, normal = {0, 1, 0}},
	}
	append(&scene, engine.Ding{
		type     = .PROP,
		pos3     = {0, -2, 0},
		mesh     = engine.gpu_create_mesh(floor_verts, []u16{0, 1, 2, 0, 2, 3}),
		material = floor_mat,
	})

	// ---- Room (4 walls + ceiling) ----
	wall_mat := alloc_material()
	wall_mat^ = engine.Material{shader = .LIT, color = {0.82, 0.78, 0.74, 1}, specular = 0.02, shininess = 8}

	ceiling_mat := alloc_material()
	ceiling_mat^ = engine.Material{shader = .LIT, color = {0.92, 0.91, 0.90, 1}, specular = 0.01, shininess = 4}

	room_verts := []engine.Vertex{
		// Front wall (z=-20), normal +Z (points into room)
		{pos = {-20, -2, -20}, normal = {0, 0, 1}}, // 0
		{pos = { 20, -2, -20}, normal = {0, 0, 1}}, // 1
		{pos = { 20,  4, -20}, normal = {0, 0, 1}}, // 2
		{pos = {-20,  4, -20}, normal = {0, 0, 1}}, // 3
		// Back wall (z=20), normal -Z
		{pos = {-20, -2,  20}, normal = {0, 0, -1}}, // 4
		{pos = { 20, -2,  20}, normal = {0, 0, -1}}, // 5
		{pos = { 20,  4,  20}, normal = {0, 0, -1}}, // 6
		{pos = {-20,  4,  20}, normal = {0, 0, -1}}, // 7
		// Left wall (x=-20), normal +X
		{pos = {-20, -2, -20}, normal = {1, 0, 0}}, // 8
		{pos = {-20, -2,  20}, normal = {1, 0, 0}}, // 9
		{pos = {-20,  4,  20}, normal = {1, 0, 0}}, // 10
		{pos = {-20,  4, -20}, normal = {1, 0, 0}}, // 11
		// Right wall (x=20), normal -X
		{pos = { 20, -2, -20}, normal = {-1, 0, 0}}, // 12
		{pos = { 20, -2,  20}, normal = {-1, 0, 0}}, // 13
		{pos = { 20,  4,  20}, normal = {-1, 0, 0}}, // 14
		{pos = { 20,  4, -20}, normal = {-1, 0, 0}}, // 15
		// Ceiling (y=4), normal -Y
		{pos = {-20, 4, -20}, normal = {0, -1, 0}}, // 16
		{pos = { 20, 4, -20}, normal = {0, -1, 0}}, // 17
		{pos = { 20, 4,  20}, normal = {0, -1, 0}}, // 18
		{pos = {-20, 4,  20}, normal = {0, -1, 0}}, // 19
	}
	room_indices := []u16{
		0,  1,  2,   0,  2,  3,  // front  (+Z)
		4,  6,  5,   4,  7,  6,  // back   (-Z)
		8,  10, 9,   8,  11, 10, // left   (+X)
		12, 13, 14,  12, 14, 15, // right  (-X)
		16, 18, 17,  16, 19, 18, // ceil   (-Y)
	}
	// Walls and ceiling share separate Dings so they can get different materials.
	// For now we split at the index level using one mesh for walls, one for ceiling.
	wall_verts := room_verts[:16]
	wall_idx   := room_indices[:24]
	append(&scene, engine.Ding{
		type     = .PROP,
		mesh     = engine.gpu_create_mesh(wall_verts, wall_idx),
		material = wall_mat,
	})
	ceil_verts := room_verts[16:]
	ceil_idx   := []u16{0, 2, 1, 0, 3, 2}
	append(&scene, engine.Ding{
		type     = .PROP,
		mesh     = engine.gpu_create_mesh(ceil_verts, ceil_idx),
		material = ceiling_mat,
	})

	// ---- Triangles ----
	red_mat   := alloc_material()
	green_mat := alloc_material()
	blue_mat  := alloc_material()
	red_mat^   = engine.Material{shader = .UNLIT, color = {1, 0.2, 0.2, 1}}
	green_mat^ = engine.Material{shader = .UNLIT, color = {0.2, 1, 0.2, 1}}
	blue_mat^  = engine.Material{shader = .UNLIT, color = {0.2, 0.4, 1, 1}}

	tri_verts := []engine.Vertex{
		{pos = { 0,  1, 0}, normal = {0, 0, 1}},
		{pos = {-1, -1, 0}, normal = {0, 0, 1}},
		{pos = { 1, -1, 0}, normal = {0, 0, 1}},
	}
	tri_mesh := engine.gpu_create_mesh(tri_verts, []u16{0, 1, 2})

	tri_mats := [5]^engine.Material{red_mat, green_mat, blue_mat, red_mat, blue_mat}
	tri_positions := [][3]f32{
		{0, 0, -5}, {4, 0, -8}, {-4, 0, -8}, {2, 2, -12}, {-2, -2, -12},
	}
	for p, i in tri_positions {
		append(&scene, engine.Ding{
			type     = .TRIANGLE,
			pos3     = p,
			mesh     = tri_mesh,
			material = tri_mats[i],
		})
	}

	// ---- OBJ cube (M9 verification) ----
	if cube_mesh, ok := engine.obj_load("assets/cube.obj"); ok {
		cube_mat := alloc_material()
		cube_mat^ = engine.Material{shader = .LIT, color = {1, 0.8, 0.2, 1}, specular = 0.4, shininess = 64}
		append(&scene, engine.Ding{
			type     = .PROP,
			pos3     = {0, 0, -3},
			mesh     = cube_mesh,
			material = cube_mat,
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
