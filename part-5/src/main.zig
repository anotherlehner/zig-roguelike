//! zig-roguelike, by @trymartinlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const models = @import("models.zig");
const engine = @import("engine.zig");
const constants = @import("constants.zig");
const procgen = @import("procgen.zig");
const ef = @import("entity_factories.zig");
const expect = std.testing.expect;

// import tests from dependency modules
test {
    _ = @import("tcod.zig");
    _ = @import("engine.zig");
    _ = @import("models.zig");
    _ = @import("procgen.zig");
}

pub fn main() anyerror!void {
    tcod.consoleInitRoot(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "Zig Roguelike", false);
    defer {
        tcod.quit();
    }
    tcod.consoleSetCustomFont("../dejavu10x10_gs_tc.png");

    var console = tcod.consoleNew(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("FAIL");
    }

    var player = try ef.player(0, 0, allocator);

    var map = try procgen.generateDungeon(constants.MAX_ROOMS, constants.ROOM_MIN_SIZE, constants.ROOM_MAX_SIZE, 
        constants.ROOM_MAX_MONSTERS, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, player, allocator);
    defer {
        map.deinit();
    }

    var eng = engine.Engine.init(player, console, &map);

    while (!tcod.consoleIsWindowClosed() and !eng.isQuit) {
        eng.render();
        eng.handleEvents();
    }
}
