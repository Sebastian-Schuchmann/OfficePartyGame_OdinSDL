package engine

import "core:mem"
import "core:os"
import sdl "vendor:sdl3"

Vertex :: struct {
	pos: [3]f32,
	col: [4]f32,
}

gpu_device:   ^sdl.GPUDevice
gpu_pipeline: ^sdl.GPUGraphicsPipeline

gpu_cmd_buf:     ^sdl.GPUCommandBuffer
gpu_render_pass: ^sdl.GPURenderPass

gpu_vertex_buf:   ^sdl.GPUBuffer
gpu_depth_texture: ^sdl.GPUTexture

triangle_verts := [3]Vertex {
	{pos = {0, 1, 0}, col = {1, 0, 0, 1}},
	{pos = {-1, -1, 0}, col = {0, 1, 0, 1}},
	{pos = {1, -1, 0}, col = {0, 0, 1, 1}},
}

DEPTH_FORMAT :: sdl.GPUTextureFormat.D32_FLOAT

gpu_create_depth_texture :: proc(w, h: u32) {
	if gpu_depth_texture != nil {
		sdl.ReleaseGPUTexture(gpu_device, gpu_depth_texture)
	}
	gpu_depth_texture = sdl.CreateGPUTexture(gpu_device, {
		type                 = .D2,
		format               = DEPTH_FORMAT,
		usage                = {.DEPTH_STENCIL_TARGET},
		width                = w,
		height               = h,
		layer_count_or_depth = 1,
		num_levels           = 1,
	})
}

gpu_on_resize :: proc(w, h: i32) {
	gpu_create_depth_texture(u32(w), u32(h))
}

gpu_init :: proc(window: ^sdl.Window) {
	gpu_device = sdl.CreateGPUDevice({.MSL}, true, nil)
	_ = sdl.ClaimWindowForGPUDevice(gpu_device, window)

	w, h: i32
	sdl.GetWindowSize(window, &w, &h)
	gpu_create_depth_texture(u32(w), u32(h))

	msl_bytes, _ := os.read_entire_file("shaders/triangle.metal")

	vert_shader := sdl.CreateGPUShader(
		gpu_device,
		{
			format              = {.MSL},
			stage               = .VERTEX,
			code_size           = len(msl_bytes),
			code                = raw_data(msl_bytes),
			entrypoint          = "vert_main",
			num_uniform_buffers = 1,
		},
	)

	frag_shader := sdl.CreateGPUShader(
		gpu_device,
		{
			format    = {.MSL},
			stage     = .FRAGMENT,
			code_size = len(msl_bytes),
			code      = raw_data(msl_bytes),
			entrypoint = "frag_main",
		},
	)

	swapchain_fmt := sdl.GetGPUSwapchainTextureFormat(gpu_device, window)

	gpu_pipeline = sdl.CreateGPUGraphicsPipeline(
		gpu_device,
		{
			vertex_shader   = vert_shader,
			fragment_shader = frag_shader,
			primitive_type  = .TRIANGLELIST,
			vertex_input_state = {
				num_vertex_buffers         = 1,
				vertex_buffer_descriptions = &sdl.GPUVertexBufferDescription {
					slot       = 0,
					pitch      = size_of(Vertex),
					input_rate = .VERTEX,
				},
				num_vertex_attributes = 2,
				vertex_attributes     = raw_data(
					[]sdl.GPUVertexAttribute {
						{location = 0, buffer_slot = 0, format = .FLOAT3, offset = 0},
						{location = 1, buffer_slot = 0, format = .FLOAT4, offset = size_of([2]f32)},
					},
				),
			},
			depth_stencil_state = {
				enable_depth_test  = true,
				enable_depth_write = true,
				compare_op         = .LESS,
			},
			target_info = {
				num_color_targets             = 1,
				color_target_descriptions     = &sdl.GPUColorTargetDescription{format = swapchain_fmt},
				has_depth_stencil_target      = true,
				depth_stencil_format          = DEPTH_FORMAT,
			},
		},
	)

	sdl.ReleaseGPUShader(gpu_device, vert_shader)
	sdl.ReleaseGPUShader(gpu_device, frag_shader)

	gpu_vertex_buf = sdl.CreateGPUBuffer(
		gpu_device,
		{usage = {.VERTEX}, size = size_of(triangle_verts)},
	)

	transfer := sdl.CreateGPUTransferBuffer(
		gpu_device,
		{usage = .UPLOAD, size = size_of(triangle_verts)},
	)
	ptr := sdl.MapGPUTransferBuffer(gpu_device, transfer, false)
	mem.copy(ptr, &triangle_verts, size_of(triangle_verts))
	sdl.UnmapGPUTransferBuffer(gpu_device, transfer)

	upload_cmd := sdl.AcquireGPUCommandBuffer(gpu_device)
	copy_pass  := sdl.BeginGPUCopyPass(upload_cmd)
	sdl.UploadToGPUBuffer(
		copy_pass,
		sdl.GPUTransferBufferLocation{transfer_buffer = transfer},
		sdl.GPUBufferRegion{buffer = gpu_vertex_buf, size = size_of(triangle_verts)},
		false,
	)
	sdl.EndGPUCopyPass(copy_pass)
	_ = sdl.SubmitGPUCommandBuffer(upload_cmd)
	sdl.ReleaseGPUTransferBuffer(gpu_device, transfer)
}

gpu_begin_frame :: proc(window: ^sdl.Window) -> bool {
	gpu_cmd_buf = sdl.AcquireGPUCommandBuffer(gpu_device)
	swapchain: ^sdl.GPUTexture
	_ = sdl.AcquireGPUSwapchainTexture(gpu_cmd_buf, window, &swapchain, nil, nil)
	if swapchain == nil do return false

	color_target := sdl.GPUColorTargetInfo {
		texture     = swapchain,
		load_op     = .CLEAR,
		clear_color = {0, 0.2, 0.4, 1},
		store_op    = .STORE,
	}
	depth_target := sdl.GPUDepthStencilTargetInfo {
		texture          = gpu_depth_texture,
		load_op          = .CLEAR,
		clear_depth      = 1.0,
		store_op         = .DONT_CARE,
		stencil_load_op  = .DONT_CARE,
		stencil_store_op = .DONT_CARE,
	}
	gpu_render_pass = sdl.BeginGPURenderPass(gpu_cmd_buf, &color_target, 1, &depth_target)
	sdl.BindGPUGraphicsPipeline(gpu_render_pass, gpu_pipeline)
	return true
}

gpu_end_frame :: proc() {
	sdl.EndGPURenderPass(gpu_render_pass)
	_ = sdl.SubmitGPUCommandBuffer(gpu_cmd_buf)
}

gpu_draw_triangle :: proc(pos: Vec3, view_proj_mat: Mat4) {
	mvp := view_proj_mat * mat4_translate3(pos)
	sdl.PushGPUVertexUniformData(gpu_cmd_buf, 0, &mvp, size_of(mvp))

	binding := sdl.GPUBufferBinding{buffer = gpu_vertex_buf}
	sdl.BindGPUVertexBuffers(gpu_render_pass, 0, &binding, 1)

	sdl.DrawGPUPrimitives(gpu_render_pass, 3, 1, 0, 0)
}
