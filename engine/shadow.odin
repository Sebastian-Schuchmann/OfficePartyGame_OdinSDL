package engine

import "core:math"
import "core:math/linalg"
import "core:os"
import sdl "vendor:sdl3"

SHADOW_MAP_SIZE :: u32(2048)

gpu_shadow_map:      ^sdl.GPUTexture
gpu_shadow_pipeline: ^sdl.GPUGraphicsPipeline
gpu_shadow_sampler:  ^sdl.GPUSampler
gpu_light_space_mat: Mat4

// ShadowUniforms mirrors the shadow vertex shader struct.
ShadowUniforms :: struct {
	light_space: Mat4,
}

// LightSpaceUniforms is pushed to the lit/textured_lit vertex shaders.
LightSpaceUniforms :: struct {
	light_vp: Mat4,
}

shadow_init :: proc() {
	// Create shadow map texture — must support both depth target and sampling.
	gpu_shadow_map = sdl.CreateGPUTexture(gpu_device, {
		type                 = .D2,
		format               = DEPTH_FORMAT,
		usage                = {.DEPTH_STENCIL_TARGET, .SAMPLER},
		width                = SHADOW_MAP_SIZE,
		height               = SHADOW_MAP_SIZE,
		layer_count_or_depth = 1,
		num_levels           = 1,
	})

	// Shadow sampler — nearest filter, clamp to edge.
	// We do the depth comparison manually in the shader.
	gpu_shadow_sampler = sdl.CreateGPUSampler(gpu_device, {
		min_filter     = .NEAREST,
		mag_filter     = .NEAREST,
		mipmap_mode    = .NEAREST,
		address_mode_u = .CLAMP_TO_EDGE,
		address_mode_v = .CLAMP_TO_EDGE,
		address_mode_w = .CLAMP_TO_EDGE,
	})

	// Build shadow pipeline — depth only, no color targets.
	msl_bytes, _ := os.read_entire_file("shaders/shadow.metal")

	vert_shader := sdl.CreateGPUShader(gpu_device, {
		format              = {.MSL},
		stage               = .VERTEX,
		code_size           = len(msl_bytes),
		code                = raw_data(msl_bytes),
		entrypoint          = "vert_main",
		num_uniform_buffers = 1,
	})

	frag_shader := sdl.CreateGPUShader(gpu_device, {
		format     = {.MSL},
		stage      = .FRAGMENT,
		code_size  = len(msl_bytes),
		code       = raw_data(msl_bytes),
		entrypoint = "frag_main",
	})

	gpu_shadow_pipeline = sdl.CreateGPUGraphicsPipeline(gpu_device, {
		vertex_shader   = vert_shader,
		fragment_shader = frag_shader,
		primitive_type  = .TRIANGLELIST,
		vertex_input_state = {
			num_vertex_buffers         = 1,
			vertex_buffer_descriptions = &sdl.GPUVertexBufferDescription{
				slot       = 0,
				pitch      = size_of(Vertex),
				input_rate = .VERTEX,
			},
			num_vertex_attributes = 3,
			vertex_attributes     = raw_data(
				[]sdl.GPUVertexAttribute{
					{location = 0, buffer_slot = 0, format = .FLOAT3, offset = 0},
					{location = 1, buffer_slot = 0, format = .FLOAT3, offset = 12},
					{location = 2, buffer_slot = 0, format = .FLOAT2, offset = 24},
				},
			),
		},
		rasterizer_state = {
			cull_mode  = .BACK,
			front_face = .COUNTER_CLOCKWISE,
		},
		depth_stencil_state = {
			enable_depth_test  = true,
			enable_depth_write = true,
			compare_op         = .LESS,
		},
		target_info = {
			num_color_targets        = 0,
			has_depth_stencil_target = true,
			depth_stencil_format     = DEPTH_FORMAT,
		},
	})

	sdl.ReleaseGPUShader(gpu_device, vert_shader)
	sdl.ReleaseGPUShader(gpu_device, frag_shader)
}

// shadow_compute_light_mat updates gpu_light_space_mat from the current
// gpu_dir_light direction. Call once per frame before the shadow pass.
// The ortho frustum covers a 60x60x100 box centered at the scene origin.
shadow_compute_light_mat :: proc() {
	dir := linalg.normalize(gpu_dir_light.direction)
	eye := Vec3{0, 2, 0} - dir * 50 // step back along -light_dir from center
	up  := Vec3{0, 1, 0}
	// If direction is nearly vertical, use a different up vector
	if math.abs(dir.y) > 0.99 {
		up = {1, 0, 0}
	}
	view   := mat4_lookat(eye, {0, 2, 0}, up)
	// Orthographic projection sized to cover the 40x40x6 room + some margin.
	// Metal NDC z is [0,1]; use mat4_ortho_depth for correct range.
	proj   := mat4_ortho_shadow(-35, 35, -35, 35, 0.1, 120)
	gpu_light_space_mat = proj * view
}

// mat4_ortho_shadow: orthographic for shadow map, z maps [near,far] -> [0,1].
mat4_ortho_shadow :: proc(left, right, bottom, top, near, far: f32) -> Mat4 {
	rl := right - left
	tb := top - bottom
	fn := far - near
	return Mat4{
		2 / rl, 0,      0,       -(right + left) / rl,
		0,      2 / tb, 0,       -(top + bottom) / tb,
		0,      0,      1 / fn,  -near / fn,
		0,      0,      0,       1,
	}
}

// shadow_begin_pass starts the depth-only shadow render pass.
// After calling this, draw all opaque meshes with shadow_draw_mesh.
// End with shadow_end_pass.
shadow_cmd_buf: ^sdl.GPUCommandBuffer
shadow_render_pass: ^sdl.GPURenderPass

shadow_begin_pass :: proc() {
	shadow_compute_light_mat()

	shadow_cmd_buf = sdl.AcquireGPUCommandBuffer(gpu_device)
	depth_target := sdl.GPUDepthStencilTargetInfo{
		texture          = gpu_shadow_map,
		load_op          = .CLEAR,
		clear_depth      = 1.0,
		store_op         = .STORE,
		stencil_load_op  = .DONT_CARE,
		stencil_store_op = .DONT_CARE,
	}
	shadow_render_pass = sdl.BeginGPURenderPass(shadow_cmd_buf, nil, 0, &depth_target)
	sdl.BindGPUGraphicsPipeline(shadow_render_pass, gpu_shadow_pipeline)
}

shadow_draw_mesh :: proc(mesh: GpuMesh, model_mat: Mat4) {
	if mesh.vertex_buf == nil do return
	su := ShadowUniforms{light_space = gpu_light_space_mat * model_mat}
	sdl.PushGPUVertexUniformData(shadow_cmd_buf, 0, &su, size_of(su))
	v_binding := sdl.GPUBufferBinding{buffer = mesh.vertex_buf}
	i_binding := sdl.GPUBufferBinding{buffer = mesh.index_buf}
	sdl.BindGPUVertexBuffers(shadow_render_pass, 0, &v_binding, 1)
	sdl.BindGPUIndexBuffer(shadow_render_pass, i_binding, ._16BIT)
	sdl.DrawGPUIndexedPrimitives(shadow_render_pass, mesh.index_count, 1, 0, 0, 0)
}

shadow_draw_ding :: proc(ding: Ding) {
	if ding.mesh.vertex_buf == nil do return
	shadow_draw_mesh(ding.mesh, mat4_translate3(ding.pos3))
}

shadow_end_pass :: proc() {
	sdl.EndGPURenderPass(shadow_render_pass)
	_ = sdl.SubmitGPUCommandBuffer(shadow_cmd_buf)
}
