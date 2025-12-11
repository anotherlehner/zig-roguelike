//! zig-roguelike, by @anotherlehner

const std = @import("std");
const color = @import("color.zig");
const constants = @import("constants.zig");
const map = @import("map.zig");
const expect = std.testing.expect;

const c = @cImport({
    @cInclude("libtcod.h");
});

pub const TcodConsole = *c.TCOD_Console;
pub const TcodColorRGBA = c.TCOD_ColorRGBA;
pub const TcodColorRGB = c.TCOD_ColorRGB;
pub const TcodKey = c.TCOD_key_t;
pub const TcodMouse = c.TCOD_mouse_t;
pub const TcodEvent = c.TCOD_event_t;
pub const TcodMap = c.TCOD_map_t;
pub const TcodPath = c.TCOD_path_t;
pub const TcodCallback = c.TCOD_path_func_t;

pub const TcodEventKeyPress = c.TCOD_EVENT_KEY_PRESS;

pub const KeyEscape = c.TCODK_ESCAPE;
pub const KeyUp = c.TCODK_UP;
pub const KeyDown = c.TCODK_DOWN;
pub const KeyLeft = c.TCODK_LEFT;
pub const KeyRight = c.TCODK_RIGHT;
pub const KeyNone = c.TCODK_NONE;
pub const KeyJ = c.TCODK_J;

pub fn init() TcodConsole {
    consoleInitRoot(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, constants.TITLE, false);
    consoleSetCustomFont(constants.TILESET);
    return consoleNew(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);
}

pub fn initKeyWithVk(initialVk: c_uint) TcodKey {
    var k = initEmptyKey();
    k.vk = initialVk;
    return k;
}

pub fn initEmptyMouse() TcodMouse {
    return TcodMouse{.x=undefined,.y=undefined,.dx=undefined,.dy=undefined,.cx=-1,.cy=-1,.dcx=undefined,.dcy=undefined,.lbutton=undefined,.rbutton=undefined,.mbutton=undefined,.lbutton_pressed=undefined,.rbutton_pressed=undefined,.mbutton_pressed=undefined,.wheel_up=undefined,.wheel_down=undefined};
}

pub fn initEmptyKey() TcodKey {
    return TcodKey{ .vk = KeyNone, .c = 0, .text = undefined, .pressed = undefined, .lalt = undefined, .lctrl = undefined, .lmeta = undefined, .ralt = undefined, .rctrl = undefined, .rmeta = undefined, .shift = undefined };
}

pub fn consoleInitRoot(width: i32, height: i32, title: [*]const u8, fullscreen: bool) void {
    _ = c.TCOD_console_init_root(width, height, title, fullscreen, c.TCOD_RENDERER_SDL2);
}

pub fn quit() void {
    c.TCOD_quit();
}

pub fn consoleSetCustomFont(filepath: [*]const u8) void {
    _ = c.TCOD_console_set_custom_font(filepath, c.TCOD_FONT_TYPE_GREYSCALE | c.TCOD_FONT_LAYOUT_TCOD, 0, 0);
}

pub fn consoleNew(width: i32, height: i32) TcodConsole {
    return c.TCOD_console_new(width, height);
}

pub fn consoleIsWindowClosed() bool {
    return c.TCOD_console_is_window_closed();
}

pub fn consolePutCharEx(con: TcodConsole, x: i32, y: i32, character: u8, fore: TcodColorRGB, back: TcodColorRGB) void {
    c.TCOD_console_put_char_ex(con, x, y, character, fore, back);
}

pub fn consoleClear(con: TcodConsole) void {
    c.TCOD_console_clear(con);
}

pub fn consoleBlit(con: TcodConsole, width: i32, height: i32) void {
    c.TCOD_console_blit(con,0,0,width,height,null,0,0,1.0,1.0);
}

pub fn sysCheckForEvent(key: *TcodKey, mouse: *TcodMouse) TcodEvent {
    return c.TCOD_sys_check_for_event(c.TCOD_EVENT_ANY, key, mouse);
}

pub fn consoleFlush() void {
    _ = c.TCOD_console_flush();
}

pub fn lineInit(xFrom: i32, yFrom: i32, xTo: i32, yTo: i32) void {
    c.TCOD_line_init(xFrom, yFrom, xTo, yTo);
}

pub fn lineStep(x: *i32, y: *i32) bool {
    return c.TCOD_line_step(x,y);
}

pub fn mapNew(width: i32, height: i32) TcodMap {
    return c.TCOD_map_new(width, height);
}

pub fn mapSetProperties(m: TcodMap, x: i32, y: i32, isTransparent: bool, isWalkable: bool) void {
    c.TCOD_map_set_properties(m, x, y, isTransparent, isWalkable);
}

pub fn mapClear(m: TcodMap, isTransparent: bool, isWalkable: bool) void {
    c.TCOD_map_clear(m, isTransparent, isWalkable);
}

pub fn mapIsInFov(m: TcodMap, x: i32, y: i32) bool {
    return c.TCOD_map_is_in_fov(m, x, y);
}

pub fn mapIsWalkable(m: TcodMap, x: i32, y: i32) bool {
    return c.TCOD_map_is_walkable(m, x, y);
}

pub fn computeFov(m: TcodMap, povX: i32, povY: i32) void {
    _ = c.TCOD_map_compute_fov(m, povX, povY, 8, true, c.FOV_BASIC);
}

test "initKeyWithVk should set given key on returned structure" {
    const key = initKeyWithVk(KeyUp);
    try expect(key.vk == KeyUp);
}

pub fn setFps(fpsValue: c_int) void {
    c.TCOD_sys_set_fps(fpsValue);
}

pub fn pathNewUsingMap(m: TcodMap) TcodPath {
    return c.TCOD_path_new_using_map(m, 1.41);
}

pub fn pathNewUsingFn(width: i32, height: i32, callback: TcodCallback, userData: *anyopaque) TcodPath {
    return c.TCOD_path_new_using_function(width, height, callback, userData, 1.41);
}

pub fn pathDelete(path: TcodPath) void {
    c.TCOD_path_delete(path);
}

pub fn pathCompute(path: TcodPath, ox: i32, oy: i32, dx: i32, dy: i32) bool {
    return c.TCOD_path_compute(path, ox, oy, dx, dy);
}

pub fn pathSize(path: TcodPath) i32 {
    return c.TCOD_path_size(path);
}

pub fn pathGet(path: TcodPath, index: i32, x: *i32, y: *i32) void {
    c.TCOD_path_get(path, index, x, y);
}

pub fn pathIsEmpty(path: TcodPath) bool {
    return c.TCOD_path_is_empty(path);
}

pub fn pathWalk(path: TcodPath, x: *i32, y: *i32) bool {
    return c.TCOD_path_walk(path,x,y,true);
}

pub fn consolePrint(console: TcodConsole, x: i32, y: i32, fmt: []u8) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        consolePutCharEx(console, x+xi, y, ch, TcodColorRGB{.r=255,.g=255,.b=255}, TcodColorRGB{.r=0,.g=0,.b=0});
        xi += 1;
    }
}

/// Prints a string setting only the foreground color and leaving the bg alone
pub fn consolePrintFg(console: TcodConsole, x: i32, y: i32, fmt: []u8, fg: TcodColorRGB) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        c.TCOD_console_set_char(console, x+xi, y, ch);
        c.TCOD_console_set_char_foreground(console, x+xi, y, fg);
        xi += 1;
    }
}

pub fn consolePrintFgMaxLength(console: TcodConsole, x: i32, y: i32, fmt: []u8, fg: TcodColorRGB, maxLength: i32) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        if (xi > maxLength) return;
        c.TCOD_console_set_char(console, x+xi, y, ch);
        c.TCOD_console_set_char_foreground(console, x+xi, y, fg);
        xi += 1;
    }
}

pub fn consoleDrawRectRgb(console: TcodConsole, x: i32, y: i32, width: i32, height: i32, ch: u8, fg: TcodColorRGB, bg: TcodColorRGB) void {
    c.TCOD_console_draw_rect_rgb(console, x, y, width, height, ch, &fg, &bg, c.TCOD_BKGND_SET);
}