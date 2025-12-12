//! zig-roguelike, by @anotherlehner

const std = @import("std");
const models = @import("models.zig");
const expect = std.testing.expect;

const c = @cImport({
    @cInclude("libtcod.h");
});

pub const TcodConsole = *c.TCOD_Console;
pub const TcodColorRGBA = c.TCOD_ColorRGBA;
pub const TcodColorRGB = c.TCOD_ColorRGB;
pub const TcodKey = c.TCOD_key_t;
pub const TcodMouse = c.TCOD_mouse_t;
pub const KeyEscape = c.TCODK_ESCAPE;
pub const KeyUp = c.TCODK_UP;
pub const KeyDown = c.TCODK_DOWN;
pub const KeyLeft = c.TCODK_LEFT;
pub const KeyRight = c.TCODK_RIGHT;
pub const KeyNone = c.TCODK_NONE;
pub const TcodMap = c.TCOD_map_t;

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

pub fn sysCheckForEvent(key: *TcodKey) void {
    _ = c.TCOD_sys_check_for_event(c.TCOD_EVENT_KEY_PRESS, key, null);
}

pub fn consoleFlush() void {
    _ = c.TCOD_console_flush();
}

pub fn renderMap(console: TcodConsole, map: *models.Map) void {
    var x: i32 = 0;
    var y: i32 = 0;
    for (map.cells, 0..) |t, index| {
        if (mapIsInFov(map.tcMap, x, y)) {
            map.cells[index].visible = true;
            map.cells[index].explored = true;
        } else {
            map.cells[index].visible = false;
        }

        if (t.visible) {
            console.tiles[index].ch = t.light.ch;
            console.tiles[index].fg = t.light.fg;
            console.tiles[index].bg = t.light.bg;
        } else if (t.explored) {
            console.tiles[index].ch = t.dark.ch;
            console.tiles[index].fg = t.dark.fg;
            console.tiles[index].bg = t.dark.bg;
        } else {
            console.tiles[index].ch = models.SHROUD.ch;
            console.tiles[index].fg = models.SHROUD.fg;
            console.tiles[index].bg = models.SHROUD.bg;
        }

        x += 1;
        if (@mod(x,map.width) == 0) {
            y += 1;
            x = 0;
        }
    }
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

pub fn mapSetProperties(map: TcodMap, x: i32, y: i32, isTransparent: bool, isWalkable: bool) void {
    c.TCOD_map_set_properties(map, x, y, isTransparent, isWalkable);
}

pub fn mapClear(map: TcodMap, isTransparent: bool, isWalkable: bool) void {
    c.TCOD_map_clear(map, isTransparent, isWalkable);
}

pub fn mapIsInFov(map: TcodMap, x: i32, y: i32) bool {
    return c.TCOD_map_is_in_fov(map, x, y);
}

pub fn mapIsWalkable(map: TcodMap, x: i32, y: i32) bool {
    return c.TCOD_map_is_walkable(map, x, y);
}

pub fn computeFov(map: TcodMap, povX: i32, povY: i32) void {
    _ = c.TCOD_map_compute_fov(map, povX, povY, 8, true, c.FOV_BASIC);
}
