//! zig-roguelike, by @anotherlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const engine = @import("engine.zig");
const constants = @import("constants.zig");
const procgen = @import("procgen.zig");
const ent = @import("entity.zig");
const expect = std.testing.expect;

test {
    // import tests from all modules
    _ = @import("tcod.zig");
    _ = @import("engine.zig");
    _ = @import("procgen.zig");
    _ = @import("map.zig");
}

pub fn main() anyerror!void {
    // Create the libtcod console
    var console = tcod.init();
    tcod.setFps(20);
    defer {
        tcod.quit();
    }

    // Initialize the memory allocator for the whole program
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("FAIL");
    }

    // Create game structures and the engine
    var player = try ent.player(0, 0, allocator);
    var map = try procgen.generateDungeon(constants.MAX_ROOMS, constants.ROOM_MIN_SIZE, constants.ROOM_MAX_SIZE, 
        constants.ROOM_MAX_MONSTERS, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, player, allocator);
    defer {
        map.deinit();
    }
    var eng = engine.Engine.init(player, console, &map);

    // Run the game
    eng.run();
}
