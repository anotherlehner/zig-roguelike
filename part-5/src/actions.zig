//! zig-roguelike, by @anotherlehner

const std = @import("std");
const mdl = @import("models.zig");
const engine = @import("engine.zig");

pub fn perform(action: mdl.ActionType, eng: *engine.Engine) void {
    switch (action) {
        mdl.ActionType.escapeAction => performEscapeAction(eng),
        mdl.ActionType.bumpAction => |b| performBumpAction(eng.map, eng.player, b),
    }
}

fn performEscapeAction(eng: *engine.Engine) void {
    std.log.info("EscapeAction: quitting...", .{});
    eng.quit();
}

fn performBumpAction(map: *mdl.Map, player: *mdl.Entity, bump: mdl.BumpAction) void {
    const nx = player.x+bump.dx;
    const ny = player.y+bump.dy;
    if (map.getBlockingEntity(nx,ny)) |target| {
        performMeleeAction(map, player, target);
    } else {
        performMoveAction(map, player, nx, ny);
    }
}

fn performMoveAction(map: *mdl.Map, player: *mdl.Entity, nx: i32, ny: i32) void {
    if (map.isWalkable(nx,ny)) {
        player.x = nx;
        player.y = ny;
    }
}

fn performMeleeAction(map: *mdl.Map, player: *mdl.Entity, target: *mdl.Entity) void {
    _ = player;
    _ = map;
    std.debug.print("You kick {s}\n", .{target.name});
}