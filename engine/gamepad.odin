package engine

import sdl "vendor:sdl3"

// GamepadState holds normalized gamepad axis values for one frame.
// All values are in [-1, 1] range (axes) or bool (buttons).
// Dead zone is applied; values within DEAD_ZONE are reported as 0.
GamepadState :: struct {
	left_x:  f32, // left stick horizontal
	left_y:  f32, // left stick vertical
	right_x: f32, // right stick horizontal (look)
	right_y: f32, // right stick vertical (look)
	a:       bool,
	b:       bool,
	x:       bool,
	y:       bool,
}

GAMEPAD_DEAD_ZONE :: f32(0.12)
GAMEPAD_AXIS_MAX  :: f32(32767)

gamepad: ^sdl.Gamepad

// gamepad_on_added tries to open a newly connected gamepad.
// Call from the GAMEPAD_ADDED event handler.
gamepad_on_added :: proc(instance_id: sdl.JoystickID) {
	if gamepad != nil do return // already have one
	gamepad = sdl.OpenGamepad(instance_id)
}

// gamepad_on_removed closes the gamepad if it matches the disconnected one.
// Call from the GAMEPAD_REMOVED event handler.
gamepad_on_removed :: proc(instance_id: sdl.JoystickID) {
	if gamepad == nil do return
	if sdl.GetGamepadID(gamepad) == instance_id {
		sdl.CloseGamepad(gamepad)
		gamepad = nil
	}
}

// gamepad_poll reads the current state of the first connected gamepad.
// Returns a zeroed GamepadState if no gamepad is connected.
gamepad_poll :: proc() -> GamepadState {
	if gamepad == nil do return {}

	axis :: proc(g: ^sdl.Gamepad, a: sdl.GamepadAxis) -> f32 {
		raw := f32(sdl.GetGamepadAxis(g, a)) / GAMEPAD_AXIS_MAX
		if raw > -GAMEPAD_DEAD_ZONE && raw < GAMEPAD_DEAD_ZONE do return 0
		return raw
	}

	return GamepadState{
		left_x  = axis(gamepad, .LEFTX),
		left_y  = axis(gamepad, .LEFTY),
		right_x = axis(gamepad, .RIGHTX),
		right_y = axis(gamepad, .RIGHTY),
		a       = sdl.GetGamepadButton(gamepad, .SOUTH),
		b       = sdl.GetGamepadButton(gamepad, .EAST),
		x       = sdl.GetGamepadButton(gamepad, .WEST),
		y       = sdl.GetGamepadButton(gamepad, .NORTH),
	}
}
