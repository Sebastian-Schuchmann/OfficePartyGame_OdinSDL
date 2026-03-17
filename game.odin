package main

import "core:math" // needed for camera.fov init

proj_mat: Mat4
view_proj_mat: Mat4

player := Ding {
	pos    = Vec2{cast(f32)WINDOW_WIDTH / 2 - 60, cast(f32)WINDOW_HEIGHT / 2 - 60 + 200},
	color  = COLOR_PLAYER,
	width  = 60,
	height = 60,
	speed  = 0.66,
	type   = DingType.PLAYER,
}

camera := Ding {
	type              = DingType.CAMERA,
	fov               = math.PI / 3,
	speed             = 5,
	mouse_sensitivity = 0.002,
}

triangles := [5]Ding {
	{pos3 = Vec3{0, 0, -5}, type = DingType.TRIANGLE},
	{pos3 = Vec3{4, 0, -8}, type = DingType.TRIANGLE},
	{pos3 = Vec3{-4, 0, -8}, type = DingType.TRIANGLE},
	{pos3 = Vec3{2, 2, -12}, type = DingType.TRIANGLE},
	{pos3 = Vec3{-2, -2, -12}, type = DingType.TRIANGLE},
}

dinge: [dynamic]^Ding
og_dinge: [dynamic]Ding

game_init :: proc() {
	append(&dinge, &player)

	for ding in dinge {
		append(&og_dinge, ding^)
	}

	proj_mat = mat4_perspective(camera.fov, f32(WINDOW_WIDTH) / f32(WINDOW_HEIGHT), 0.1, 1000)
}

game_reset :: proc() {
	for i in 0 ..< len(dinge) {
		dinge[i]^ = og_dinge[i]
	}
}

game_loop :: proc() {
	camera_update()

	for t in triangles {
		gpu_draw_triangle(t.pos3)
	}
}
