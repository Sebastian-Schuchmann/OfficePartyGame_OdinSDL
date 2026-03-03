package main

import "core:fmt"
import sdl "vendor:sdl3"

Color :: struct {
    r : u8,
    g : u8,
    b : u8,
    a : u8,
}

Vec2 :: struct {
    x : f32,
    y : f32,
}

set_color :: proc(renderer: ^sdl.Renderer, color: Color) {
    sdl.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)
}

move_rect :: proc(rect : ^sdl.FRect, dir : Vec2, dt : f64) {
    dt_f32 := cast(f32) dt
    rect.x += dir.x * dt_f32
    rect.y += dir.y * dt_f32
}


main :: proc() {
    fmt.println("Hi, mom!");

    success := sdl.Init({ .VIDEO });

    window: ^sdl.Window
    renderer: ^sdl.Renderer
    ok := sdl.CreateWindowAndRenderer("Title", 1600, 1000, { .RESIZABLE }, &window, &renderer)
    sdl.SetRenderLogicalPresentation(renderer, 1600, 1000, .LETTERBOX)
    sdl.SetRenderScale(renderer, 2, 2)
    sdl.SetRenderVSync(renderer, 0)

    rect := sdl.FRect{ 0, 200, 50, 50 }
    tick := sdl.GetTicksNS()

    main_loop: for {
        ev: sdl.Event

        dt := sdl.GetTicksNS() - tick
        tick = sdl.GetTicksNS()
        dt_ms : f64 = cast(f64) dt / 1e6;
        fps := 1000.0 / dt_ms;


        left_btn_down : bool = false;
        right_btn_down : bool = false;

        for sdl.PollEvent(&ev) {
            #partial switch ev.type {
            case .QUIT:
                break main_loop
            case .KEY_DOWN:
                if ev.key.scancode == .ESCAPE do break main_loop;
                if ev.key.scancode == .LEFT do left_btn_down = true;
                if ev.key.scancode == .RIGHT do right_btn_down = true;
            }
        }


        //CLEAR
        set_color(renderer, COLOR_VIVID_ROYAL);
        sdl.RenderClear(renderer)
        //DRAW
        set_color(renderer, COLOR_WHITE)
        sdl.RenderDebugText(renderer, 0, 0, fmt.ctprintf("FPS:%d (%f)", cast(i64)fps, dt_ms))
        sdl.RenderDebugText(renderer, 0, 10, fmt.ctprintf("L:%v R:%v", left_btn_down, right_btn_down))

        set_color(renderer, COLOR_DEEP_SAFFRON);

        sdl.RenderFillRect(renderer, &rect);

        if left_btn_down {
        move_rect(&rect, Vec2{ -2, 0.0}, dt_ms);
        } else if right_btn_down {
        move_rect(&rect, Vec2{ 2, 0.0}, dt_ms);
        }

        sdl.RenderPresent(renderer)
    }
}

