//! zig-roguelike, by @anotherlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const expect = std.testing.expect;

pub fn rgba(r: u8, g: u8, b: u8, a: u8) tcod.TcodColorRGBA {
    return tcod.TcodColorRGBA{ .r = r, .g = g, .b = b, .a = a };
}

pub fn rgb(r: u8, g: u8, b: u8) tcod.TcodColorRGB {
    return tcod.TcodColorRGB{ .r = r, .g = g, .b = b };
}

pub const Graphic = struct {
    ch: u8,
    fg: tcod.TcodColorRGBA,
    bg: tcod.TcodColorRGBA,
};

pub const SHROUD = Graphic{ .ch = ' ', .fg = Black, .bg = Black };

pub const Red = tcod.TcodColorRGBA{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const Black = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const White = tcod.TcodColorRGBA{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const SoftBlue = tcod.TcodColorRGBA{ .r = 50, .g = 50, .b = 150, .a = 255 };
pub const DarkBlue = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 100, .a = 255 };
pub const Grey = tcod.TcodColorRGBA{ .r = 128, .g = 128, .b = 128, .a = 255 };

pub const White_rgb = rgb(255, 255, 255);
pub const Black_rgb = rgb(0, 0, 0);
pub const Player_atk = rgb(224, 224, 224);
pub const Player_die = rgb(255, 48, 48);
pub const Enemy_atk = rgb(255, 192, 192);
pub const Enemy_die = rgb(255, 158, 48);
pub const Welcome_text = rgb(32, 158, 255);
pub const Bar_text = White_rgb;
pub const Bar_filled = rgb(0, 96, 0);
pub const Bar_empty = rgb(64, 16, 16);

test "white rgb color" {
    const c = White_rgb;
    try expect(c.r == 255);
}
