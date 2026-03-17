package main

import "core:os"
import sdl "vendor:sdl3"

gpu_device:   ^sdl.GPUDevice
gpu_pipeline: ^sdl.GPUGraphicsPipeline

gpu_cmd_buf:     ^sdl.GPUCommandBuffer
gpu_render_pass: ^sdl.GPURenderPass

gpu_init :: proc() {
	gpu_device = sdl.CreateGPUDevice({.MSL}, true, nil)
	_ = sdl.ClaimWindowForGPUDevice(gpu_device, window)

	msl_bytes, _ := os.read_entire_file("shaders/triangle.metal")

	vert_shader := sdl.CreateGPUShader(gpu_device, {
		format     = {.MSL},
		stage      = .VERTEX,
		code_size  = len(msl_bytes),
		code       = raw_data(msl_bytes),
		entrypoint = "vert_main",
	})

	frag_shader := sdl.CreateGPUShader(gpu_device, {
		format     = {.MSL},
		stage      = .FRAGMENT,
		code_size  = len(msl_bytes),
		code       = raw_data(msl_bytes),
		entrypoint = "frag_main",
	})

	swapchain_fmt := sdl.GetGPUSwapchainTextureFormat(gpu_device, window)

	gpu_pipeline = sdl.CreateGPUGraphicsPipeline(gpu_device, {
		vertex_shader   = vert_shader,
		fragment_shader = frag_shader,
		primitive_type  = .TRIANGLELIST,
		target_info = {
			num_color_targets         = 1,
			color_target_descriptions = &sdl.GPUColorTargetDescription{
				format = swapchain_fmt,
			},
		},
	})

	sdl.ReleaseGPUShader(gpu_device, vert_shader)
	sdl.ReleaseGPUShader(gpu_device, frag_shader)
}

gpu_begin_frame :: proc() -> bool {
	gpu_cmd_buf = sdl.AcquireGPUCommandBuffer(gpu_device)
	swapchain: ^sdl.GPUTexture
	_ = sdl.AcquireGPUSwapchainTexture(gpu_cmd_buf, window, &swapchain, nil, nil)
	if swapchain == nil do return false

	color_target := sdl.GPUColorTargetInfo{
		texture     = swapchain,
		load_op     = .CLEAR,
		clear_color = {0, 0.2, 0.4, 1},
		store_op    = .STORE,
	}
	gpu_render_pass = sdl.BeginGPURenderPass(gpu_cmd_buf, &color_target, 1, nil)
	sdl.BindGPUGraphicsPipeline(gpu_render_pass, gpu_pipeline)
	return true
}

gpu_end_frame :: proc() {
	sdl.EndGPURenderPass(gpu_render_pass)
	_ = sdl.SubmitGPUCommandBuffer(gpu_cmd_buf)
}

gpu_draw_triangle :: proc() {
	sdl.DrawGPUPrimitives(gpu_render_pass, 3, 1, 0, 0)
}
