//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const models = @import("models.zig");
const engine = @import("engine.zig");

pub fn perform(action: models.ActionType, eng: *engine.Engine) void {
    switch (action) {
        models.ActionType.escapeAction => performEscapeAction(eng),
        models.ActionType.moveAction => |m| performMoveAction(eng.map, eng.player, m),
    }
}

fn performEscapeAction(eng: *engine.Engine) void {
    std.log.info("EscapeAction: quitting...", .{});
    eng.quit();
}

fn performMoveAction(map: *models.Map, player: *models.Entity, move: models.MoveAction) void {
    if (map.isWalkable(player.x+move.dx, player.y+move.dy)) {
        player.move(move.dx, move.dy);
    }
}