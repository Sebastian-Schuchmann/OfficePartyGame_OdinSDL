package engine

import "core:mem"
import "core:os"
import sdl "vendor:sdl3"

Vertex :: struct {
	pos: [3]f32,
	col: [4]f32,
}

GpuMesh :: struct {
	vertex_buf:  ^sdl.GPUBuffer,
	index_buf:   ^sdl.GPUBuffer,
	index_count: u32,
}

gpu_device:   ^sdl.GPUDevice
gpu_pipeline: ^sdl.GPUGraphicsPipeline

gpu_cmd_buf:      ^sdl.GPUCommandBuffer
gpu_render_pass:  ^sdl.GPURenderPass
gpu_depth_texture: ^sdl.GPUTexture

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

// Upload a raw byte slice to a new GPU buffer with the given usage.
gpu_upload_buffer :: proc(data: rawptr, size: int, usage: sdl.GPUBufferUsageFlags) -> ^sdl.GPUBuffer {
	buf := sdl.CreateGPUBuffer(gpu_device, {usage = usage, size = u32(size)})

	transfer := sdl.CreateGPUTransferBuffer(gpu_device, {usage = .UPLOAD, size = u32(size)})
	ptr := sdl.MapGPUTransferBuffer(gpu_device, transfer, false)
	mem.copy(ptr, data, size)
	sdl.UnmapGPUTransferBuffer(gpu_device, transfer)

	cmd  := sdl.AcquireGPUCommandBuffer(gpu_device)
	pass := sdl.BeginGPUCopyPass(cmd)
	sdl.UploadToGPUBuffer(
		pass,
		sdl.GPUTransferBufferLocation{transfer_buffer = transfer},
		sdl.GPUBufferRegion{buffer = buf, size = u32(size)},
		false,
	)
	sdl.EndGPUCopyPass(pass)
	_ = sdl.SubmitGPUCommandBuffer(cmd)
	sdl.ReleaseGPUTransferBuffer(gpu_device, transfer)

	return buf
}

// Create a GPU mesh from vertices and u16 indices.
gpu_create_mesh :: proc(verts: []Vertex, indices: []u16) -> GpuMesh {
	return GpuMesh{
		vertex_buf  = gpu_upload_buffer(raw_data(verts), len(verts) * size_of(Vertex), {.VERTEX}),
		index_buf   = gpu_upload_buffer(raw_data(indices), len(indices) * size_of(u16), {.INDEX}),
		index_count = u32(len(indices)),
	}
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
			format     = {.MSL},
			stage      = .FRAGMENT,
			code_size  = len(msl_bytes),
			code       = raw_data(msl_bytes),
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
						{location = 1, buffer_slot = 0, format = .FLOAT4, offset = size_of([3]f32)},
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
				num_color_targets         = 1,
				color_target_descriptions = &sdl.GPUColorTargetDescription{format = swapchain_fmt},
				has_depth_stencil_target  = true,
				depth_stencil_format      = DEPTH_FORMAT,
			},
		},
	)

	sdl.ReleaseGPUShader(gpu_device, vert_shader)
	sdl.ReleaseGPUShader(gpu_device, frag_shader)
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

gpu_draw_mesh :: proc(mesh: GpuMesh, pos: Vec3, view_proj_mat: Mat4) {
	mvp := view_proj_mat * mat4_translate3(pos)
	sdl.PushGPUVertexUniformData(gpu_cmd_buf, 0, &mvp, size_of(mvp))

	v_binding := sdl.GPUBufferBinding{buffer = mesh.vertex_buf}
	i_binding := sdl.GPUBufferBinding{buffer = mesh.index_buf}
	sdl.BindGPUVertexBuffers(gpu_render_pass, 0, &v_binding, 1)
	sdl.BindGPUIndexBuffer(gpu_render_pass, i_binding, ._16BIT)
	sdl.DrawGPUIndexedPrimitives(gpu_render_pass, mesh.index_count, 1, 0, 0, 0)
}

// Draw a Ding at its pos3 using its mesh. No-op if mesh is not set.
gpu_draw_ding :: proc(ding: Ding, view_proj_mat: Mat4) {
	if ding.mesh.vertex_buf == nil do return
	gpu_draw_mesh(ding.mesh, ding.pos3, view_proj_mat)
}
