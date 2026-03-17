package engine

import "core:math"
import "core:math/linalg"

Vec2 :: struct {
	x: f32,
	y: f32,
}

Vec3 :: [3]f32
Mat4 :: matrix[4, 4]f32

mat4_identity :: proc() -> Mat4 {
	return Mat4{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
}

mat4_translate :: proc(t: Vec2) -> Mat4 {
	return Mat4{1, 0, 0, t.x, 0, 1, 0, t.y, 0, 0, 1, 0, 0, 0, 0, 1}
}

mat4_translate3 :: proc(t: Vec3) -> Mat4 {
	return Mat4{1, 0, 0, t.x, 0, 1, 0, t.y, 0, 0, 1, t.z, 0, 0, 0, 1}
}

mat4_rotate_x :: proc(a: f32) -> Mat4 {
	c, s := math.cos(a), math.sin(a)
	return Mat4{1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1}
}

mat4_rotate_y :: proc(a: f32) -> Mat4 {
	c, s := math.cos(a), math.sin(a)
	return Mat4{c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1}
}

// Perspective projection for Metal NDC (z in [0,1])
mat4_perspective :: proc(fov_y, aspect, near, far: f32) -> Mat4 {
	f := 1.0 / math.tan(fov_y * 0.5)
	return Mat4 {
		f / aspect,
		0,
		0,
		0,
		0,
		f,
		0,
		0,
		0,
		0,
		far / (near - far),
		far * near / (near - far),
		0,
		0,
		-1,
		0,
	}
}

// View matrix from yaw/pitch FPS camera
mat4_view :: proc(pos: Vec3, yaw, pitch: f32) -> Mat4 {
	cx := math.cos(pitch)
	sx := math.sin(pitch)
	cy := math.cos(yaw)
	sy := math.sin(yaw)
	p := pos
	return Mat4 {
		cy,
		0,
		sy,
		-(cy * p.x + sy * p.z),
		sy * sx,
		cx,
		-cy * sx,
		-(sy * sx * p.x + cx * p.y - cy * sx * p.z),
		-sy * cx,
		sx,
		cy * cx,
		sy * cx * p.x - sx * p.y - cy * cx * p.z,
		0,
		0,
		0,
		1,
	}
}

// Look-at view matrix: eye looking toward center with given up vector.
// Up does not need to be perpendicular to (center-eye) — it is orthogonalized.
mat4_lookat :: proc(eye, center, up: Vec3) -> Mat4 {
	f := linalg.normalize(center - eye)
	r := linalg.normalize(linalg.cross(f, up))
	u := linalg.cross(r, f)
	return Mat4{
		 r.x,  r.y,  r.z, -linalg.dot(r, eye),
		 u.x,  u.y,  u.z, -linalg.dot(u, eye),
		-f.x, -f.y, -f.z,  linalg.dot(f, eye),
		 0,    0,    0,    1,
	}
}

// Orthographic projection: maps [left,right] x [bottom,top] -> [-1,1] NDC
mat4_ortho :: proc(left, right, bottom, top: f32) -> Mat4 {
	rl := right - left
	tb := top - bottom
	return Mat4 {
		2 / rl,
		0,
		0,
		-(right + left) / rl,
		0,
		2 / tb,
		0,
		-(top + bottom) / tb,
		0,
		0,
		-1,
		0,
		0,
		0,
		0,
		1,
	}
}
