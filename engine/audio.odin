package engine

import "core:c"
import sdl "vendor:sdl3"

// Sound holds a loaded WAV file in memory.
// Pass to audio_play to trigger a one-shot playback.
Sound :: struct {
	spec: sdl.AudioSpec,
	buf:  [^]sdl.Uint8,
	len:  sdl.Uint32,
}

// MusicStream wraps an AudioStream that loops a Sound.
MusicStream :: struct {
	stream: ^sdl.AudioStream,
	sound:  Sound,
}

audio_device: sdl.AudioDeviceID

// audio_init opens the default playback device.
// Call once before loading or playing any audio.
audio_init :: proc() {
	audio_device = sdl.OpenAudioDevice(sdl.AUDIO_DEVICE_DEFAULT_PLAYBACK, nil)
}

// audio_load loads a WAV file. Returns ok=false if the file is missing.
// The returned Sound.buf is owned by SDL — call audio_free to release it.
audio_load :: proc(path: string) -> (sound: Sound, ok: bool) {
	loaded := sdl.LoadWAV(cstring(raw_data(path)), &sound.spec, &sound.buf, &sound.len)
	return sound, loaded
}

// audio_free releases the memory allocated by audio_load.
audio_free :: proc(sound: Sound) {
	sdl.free(sound.buf)
}

// audio_play plays a sound once (fire-and-forget).
// Creates a temporary stream, queues the WAV data, and binds it to the device.
// SDL automatically cleans up the stream when playback finishes.
audio_play :: proc(sound: Sound) {
	// Get device output format so the stream can resample if needed
	dev_spec: sdl.AudioSpec
	sdl.GetAudioDeviceFormat(audio_device, &dev_spec, nil)

	src := sound.spec
	stream := sdl.CreateAudioStream(&src, &dev_spec)
	if stream == nil do return
	_ = sdl.PutAudioStreamData(stream, sound.buf, c.int(sound.len))
	_ = sdl.BindAudioStream(audio_device, stream)
	// Stream will auto-destroy once the device drains it — we lose our handle here
	// which is fine for fire-and-forget SFX.
	// To properly clean up, the caller would need to track and destroy the stream.
}

// audio_play_music creates a looping music stream.
// Call audio_stop_music to stop and clean up.
audio_play_music :: proc(sound: Sound) -> MusicStream {
	dev_spec: sdl.AudioSpec
	sdl.GetAudioDeviceFormat(audio_device, &dev_spec, nil)

	src := sound.spec
	stream := sdl.CreateAudioStream(&src, &dev_spec)
	_ = sdl.PutAudioStreamData(stream, sound.buf, c.int(sound.len))
	_ = sdl.BindAudioStream(audio_device, stream)

	return MusicStream{stream = stream, sound = sound}
}

// audio_music_update re-queues music data when the buffer runs low,
// creating a seamless loop. Call this each frame.
audio_music_update :: proc(music: ^MusicStream) {
	if music.stream == nil do return
	// Re-queue when less than one buffer's worth remains
	if sdl.GetAudioStreamAvailable(music.stream) < c.int(music.sound.len) / 2 {
		_ = sdl.PutAudioStreamData(music.stream, music.sound.buf, c.int(music.sound.len))
	}
}

// audio_stop_music stops and destroys a music stream.
audio_stop_music :: proc(music: ^MusicStream) {
	if music.stream == nil do return
	sdl.UnbindAudioStream(music.stream)
	sdl.DestroyAudioStream(music.stream)
	music.stream = nil
}
