package engine

import "core:mem"
import sdl "vendor:sdl3"

gpu_default_sampler: ^sdl.GPUSampler

// gpu_texture_init creates the default sampler. Called once from gpu_init.
gpu_texture_init :: proc() {
	gpu_default_sampler = sdl.CreateGPUSampler(gpu_device, {
		min_filter        = .LINEAR,
		mag_filter        = .LINEAR,
		mipmap_mode       = .NEAREST,
		address_mode_u    = .REPEAT,
		address_mode_v    = .REPEAT,
		address_mode_w    = .REPEAT,
	})
}

// gpu_load_texture loads a BMP file and uploads it to a GPU texture.
// Returns ok=false if the file is missing or conversion fails.
// The returned texture must be released with sdl.ReleaseGPUTexture when done.
gpu_load_texture :: proc(path: string) -> (tex: ^sdl.GPUTexture, ok: bool) {
	surface := sdl.LoadBMP(cstring(raw_data(path)))
	if surface == nil do return nil, false
	defer sdl.DestroySurface(surface)

	// Convert to RGBA8 in memory order (R at byte 0, G at byte 1, B at byte 2, A at byte 3)
	// RGBA32 = ABGR8888 on little-endian = memory order RGBA, matching GPU R8G8B8A8_UNORM
	rgba := sdl.ConvertSurface(surface, .RGBA32)
	if rgba == nil do return nil, false
	defer sdl.DestroySurface(rgba)

	w := u32(rgba.w)
	h := u32(rgba.h)
	size := int(w * h * 4)

	tex = sdl.CreateGPUTexture(gpu_device, {
		type                 = .D2,
		format               = .R8G8B8A8_UNORM,
		usage                = {.SAMPLER},
		width                = w,
		height               = h,
		layer_count_or_depth = 1,
		num_levels           = 1,
	})

	transfer := sdl.CreateGPUTransferBuffer(gpu_device, {usage = .UPLOAD, size = u32(size)})
	ptr := sdl.MapGPUTransferBuffer(gpu_device, transfer, false)
	mem.copy(ptr, rgba.pixels, size)
	sdl.UnmapGPUTransferBuffer(gpu_device, transfer)

	cmd  := sdl.AcquireGPUCommandBuffer(gpu_device)
	pass := sdl.BeginGPUCopyPass(cmd)
	sdl.UploadToGPUTexture(
		pass,
		sdl.GPUTextureTransferInfo{transfer_buffer = transfer, pixels_per_row = w},
		sdl.GPUTextureRegion{texture = tex, w = w, h = h, d = 1},
		false,
	)
	sdl.EndGPUCopyPass(pass)
	_ = sdl.SubmitGPUCommandBuffer(cmd)
	sdl.ReleaseGPUTransferBuffer(gpu_device, transfer)

	return tex, true
}
