//! zig-roguelike, by @trymartinlehner

const std = @import("std");
const models = @import("models.zig");

pub fn perform(action: models.ActionType, map: *models.Map, player: *models.Entity) void {
    switch (action) {
        models.ActionType.escapeAction => performEscapeAction(),
        models.ActionType.moveAction => |m| performMoveAction(map, player, m),
    }
}

fn performEscapeAction() void {
    std.log.info("EscapeAction: quitting...", .{});
    std.process.exit(0);
}

fn performMoveAction(map: *models.Map, player: *models.Entity, move: models.MoveAction) void {
    if (map.isWalkable(player.x+move.dx, player.y+move.dy)) {
        player.move(move.dx, move.dy);
    }
}