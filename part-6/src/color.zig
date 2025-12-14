//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const tcod = @import("tcod.zig");

pub const Red = tcod.TcodColorRGBA{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const Black = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const White = tcod.TcodColorRGBA{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const SoftBlue = tcod.TcodColorRGBA{ .r = 50, .g = 50, .b = 150, .a = 255 };
pub const DarkBlue = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 100, .a = 255 };

pub fn rgba(r: u8, g: u8, b: u8, a: u8) tcod.TcodColorRGBA {
    return tcod.TcodColorRGBA{.r = r, .g=g, .b=b, .a=a};
}

pub fn rgb(r: u8, g: u8, b: u8) tcod.TcodColorRGB {
    return tcod.TcodColorRGB{.r = r, .g = g, .b = b};
}

pub const Graphic = struct {
    ch: u8,
    fg: tcod.TcodColorRGBA,
    bg: tcod.TcodColorRGBA,
};

pub const SHROUD = Graphic{.ch=' ', .fg=Black, .bg=Black};