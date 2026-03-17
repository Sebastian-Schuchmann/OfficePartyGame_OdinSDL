package main

triangle_pos: Vec2

player := Ding {
	pos    = Vec2{cast(f32)WINDOW_WIDTH / 2 - 60, cast(f32)WINDOW_HEIGHT / 2 - 60 + 200},
	color  = COLOR_PLAYER,
	width  = 60,
	height = 60,
	speed  = 0.66,
	type   = DingType.PLAYER,
}

dinge: [dynamic]^Ding
og_dinge: [dynamic]Ding

game_init :: proc() {
	append(&dinge, &player)

	for ding in dinge {
		append(&og_dinge, ding^)
	}
}

game_reset :: proc() {
	for i in 0 ..< len(dinge) {
		dinge[i]^ = og_dinge[i]
	}
}

game_loop :: proc() {
	SPEED: f32 = 0.001
	if left_btn_down  do triangle_pos.x -= SPEED * cast(f32)dt_ms
	if right_btn_down do triangle_pos.x += SPEED * cast(f32)dt_ms
	if up_btn_down    do triangle_pos.y += SPEED * cast(f32)dt_ms
	if down_btn_down  do triangle_pos.y -= SPEED * cast(f32)dt_ms

	gpu_draw_triangle(triangle_pos)
}
