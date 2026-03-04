package main

import "core:fmt"
import sdl "vendor:sdl3"

left_btn_down  : bool = false
right_btn_down : bool = false

msl := `
#include <metal_stdlib>
using namespace metal;
struct VertOut {
    float4 pos [[position]];
    float4 col;
};
vertex VertOut vert_main(uint vid [[vertex_id]]) {
    float2 positions[3] = { float2(0,0.5), float2(-0.5,-0.5), float2(0.5,-0.5) };
    float4 colors[3] = { float4(1,0,0,1), float4(0,1,0,1), float4(0,0,1,1) };
    VertOut out;
    out.pos = float4(positions[vid], 0, 1);
    out.col = colors[vid];
    return out;
}
fragment float4 frag_main(VertOut in [[stage_in]]) {
    return in.col;
}
`

main :: proc() {
    ok := sdl.Init({.VIDEO})
    window   := sdl.CreateWindow("Test", 1600, 1000, {})
    gpu      := sdl.CreateGPUDevice({.MSL}, true, nil)
    ok = sdl.ClaimWindowForGPUDevice(gpu, window)
    ok = sdl.SetGPUSwapchainParameters(gpu, window, .SDR, .IMMEDIATE)

    msl_bytes := transmute([]u8)msl

    vert_shader := sdl.CreateGPUShader(gpu, {
        format     = {.MSL},
        stage      = .VERTEX,
        code_size  = len(msl_bytes),
        code       = raw_data(msl_bytes),
        entrypoint = "vert_main",
    })

    frag_shader := sdl.CreateGPUShader(gpu, {
        format     = {.MSL},
        stage      = .FRAGMENT,
        code_size  = len(msl_bytes),
        code       = raw_data(msl_bytes),
        entrypoint = "frag_main",
    })

    swapchain_fmt := sdl.GetGPUSwapchainTextureFormat(gpu, window)

    pipeline := sdl.CreateGPUGraphicsPipeline(gpu, {
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

    sdl.ReleaseGPUShader(gpu, vert_shader)
    sdl.ReleaseGPUShader(gpu, frag_shader)

    tick := sdl.GetTicksNS()

    main_loop: for {
        ev: sdl.Event

        dt    := sdl.GetTicksNS() - tick
        tick   = sdl.GetTicksNS()
        dt_ms := cast(f64) dt / 1e6
        fps   := 1000.0 / dt_ms

        for sdl.PollEvent(&ev) {
            #partial switch ev.type {
            case .QUIT:
                break main_loop
            case .KEY_DOWN:
                if ev.key.scancode == .ESCAPE do break main_loop
                if ev.key.scancode == .LEFT   do left_btn_down = true
                if ev.key.scancode == .RIGHT  do right_btn_down = true
            case .KEY_UP:
                if ev.key.scancode == .LEFT   do left_btn_down = false
                if ev.key.scancode == .RIGHT  do right_btn_down = false
            }
        }

        cmd_buf   := sdl.AcquireGPUCommandBuffer(gpu)
        swapchain : ^sdl.GPUTexture
        ok = sdl.AcquireGPUSwapchainTexture(cmd_buf, window, &swapchain, nil, nil)

        if swapchain != nil {
            color_target := sdl.GPUColorTargetInfo{
                texture     = swapchain,
                load_op     = .CLEAR,
                clear_color = {0, 0.2, 0.4, 1},
                store_op    = .STORE,
            }
            render_pass := sdl.BeginGPURenderPass(cmd_buf, &color_target, 1, nil)
            sdl.BindGPUGraphicsPipeline(render_pass, pipeline)
            sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)
            sdl.EndGPURenderPass(render_pass)
        }

        ok = sdl.SubmitGPUCommandBuffer(cmd_buf)

        fmt.println("FPS:", fps)
    }
}

//main :: proc() {
//    fmt.println("Hi, mom!");
//
//    success := sdl.Init({ .VIDEO });
//
//    window: ^sdl.Window
//    renderer: ^sdl.Renderer
//    ok := sdl.CreateWindowAndRenderer("Title", 1600, 1000, { .RESIZABLE }, &window, &renderer)
////    sdl.SetRenderLogicalPresentation(renderer, 1600, 1000, .LETTERBOX)
////    sdl.SetRenderScale(renderer, 2, 2)
//    sdl.SetRenderVSync(renderer, 0)
//
//    rect := sdl.FRect{ 0, 200, 50, 50 }
//    tick := sdl.GetTicksNS()
//
//    main_loop: for {
//        ev: sdl.Event
//
//        dt := sdl.GetTicksNS() - tick
//        tick = sdl.GetTicksNS()
//        dt_ms : f64 = cast(f64) dt / 1e6;
//        fps := 1000.0 / dt_ms;
//
//
//
//        ev_count := 0
//
//        //If I leave this part out the window never renderes
//        for sdl.PollEvent(&ev) {
//            ev_count += 1
//            #partial switch ev.type {
//            case .QUIT:
//                break main_loop
//            case .KEY_DOWN:
//                if ev.key.scancode == .ESCAPE do break main_loop;
//                if ev.key.scancode == .LEFT do left_btn_down = true;
//                if ev.key.scancode == .RIGHT do right_btn_down = true;
//            case .KEY_UP:
//                if ev.key.scancode == .LEFT do left_btn_down = false;
//                if ev.key.scancode == .RIGHT do right_btn_down = false;
//            }
//        }
//
//        fmt.println("Event count:", ev_count);
//        // Part end
//
//
//        //CLEAR
//        set_color(renderer, COLOR_VIVID_ROYAL);
//        sdl.RenderClear(renderer)
//        //DRAW
//        set_color(renderer, COLOR_WHITE)
//        sdl.RenderDebugText(renderer, 0, 0, fmt.ctprintf("FPS:%d (%f)", cast(i64)fps, dt_ms))
//        sdl.RenderDebugText(renderer, 0, 10, fmt.ctprintf("L:%v R:%v", left_btn_down, right_btn_down))
//
//        set_color(renderer, COLOR_DEEP_SAFFRON);
//
//        sdl.RenderFillRect(renderer, &rect);
//
//        if left_btn_down {
//            move_rect(&rect, Vec2{ -1, 0.0 }, dt_ms);
//        } else if right_btn_down {
//            move_rect(&rect, Vec2{ 1, 0.0 }, dt_ms);
//        }
//
//        sdl.RenderPresent(renderer)
//        fmt.println("FPS: %f", fps);
//    }
//}

