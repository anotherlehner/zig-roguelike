//! zig-roguelike, by @trymartinlehner
const std = @import("std");

const c = @cImport({
    @cInclude("libtcod.h");
});

pub fn main() anyerror!void {
    // Note that info level log messages are by default printed only in Debug
    // and ReleaseSafe build modes.
    std.log.info("tcod red: {}", .{c.TCOD_red});
}

test "tcod red has lots of red in it" {
    try std.testing.expectEqual(c.TCOD_red.r, 255);
}
