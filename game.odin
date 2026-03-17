package main

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
	SPEED := player.speed
	left_right_speed := left_btn_down ? SPEED * -1 : right_btn_down ? SPEED : 0.0

	gpu_draw_triangle()

	move_ding(&player, Vec2{left_right_speed, 0.0})
}
