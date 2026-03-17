package engine

import sdl "vendor:sdl3"

// ShaderType selects which GPU pipeline is used for a Ding.
ShaderType :: enum u8 {
	UNLIT,        // flat color from material.color; no lighting
	LIT,          // Blinn-Phong + directional light
	TEXTURED_LIT, // Blinn-Phong + albedo texture
}

// Material is a fat struct — all fields for all shaders live here.
// Unused fields are zero and never uploaded. One struct, forever.
// Add new shader properties here; never split into per-shader structs.
Material :: struct {
	shader:     ShaderType,
	// All shaders: base color (linear RGBA 0..1)
	color:      [4]f32,
	// LIT, TEXTURED_LIT
	specular:   f32,
	shininess:  f32,
	// TEXTURED_LIT
	albedo_tex: ^sdl.GPUTexture,
	normal_tex: ^sdl.GPUTexture,
	sampler:    ^sdl.GPUSampler,
	// Future
	emissive:   [3]f32,
	roughness:  f32,
	metallic:   f32,
}

// DirLight is set once per frame. Directional light only.
DirLight :: struct {
	direction: [3]f32,
	_pad0:     f32,
	color:     [3]f32,
	ambient:   f32,
}
