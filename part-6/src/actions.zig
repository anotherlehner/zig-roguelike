//! zig-roguelike, by @anotherlehner

const std = @import("std");
const ent = @import("entity.zig");
const map = @import("map.zig");
const engine = @import("engine.zig");

const Map = map.Map;
const Entity = ent.Entity;

// Structs for the available action types
pub const EscapeAction = struct {};
pub const BumpAction = struct { dx: i32, dy: i32 };
pub const WaitAction = struct {};

// This enum is used to create a tagged union of actions
pub const ActionTypeTag = enum {
    escapeAction,
    bumpAction,
    waitAction,
};

// Action type union; this structure can only have 1 active union value at a time
// and can be used in switch statements!
pub const ActionType = union(ActionTypeTag) {
    escapeAction: EscapeAction,
    bumpAction: BumpAction,
    waitAction: WaitAction,
};

// TODO: refactor so it doesn't assume the player
pub fn perform(action: ActionType, eng: *engine.Engine) void {
    switch (action) {
        ActionType.escapeAction => performEscapeAction(eng),
        ActionType.bumpAction => |b| performBumpAction(eng.map, eng.player, b),
        ActionType.waitAction => performWaitAction(),
    }
}

pub fn performWaitAction() void {
    // TODO: log
}

pub fn performEscapeAction(eng: *engine.Engine) void {
    std.log.info("EscapeAction: quitting...", .{});
    eng.quit();
}

pub fn performBumpAction(m: *Map, player: *Entity, bump: BumpAction) void {
    var nx = player.x+bump.dx;
    var ny = player.y+bump.dy;
    if (m.getBlockingEntity(nx,ny)) |target| {
        if (target.component == ent.ComponentType.fighter) {
            performMeleeAction(player, target);
        }
    } else {
        performMoveAction(m, player, nx, ny);
    }
}

pub fn performMoveAction(m: *Map, entity: *Entity, nx: i32, ny: i32) void {
    if (m.isWalkable(nx,ny)) {
        entity.x = nx;
        entity.y = ny;
    }
}

pub fn performMeleeAction(source: *Entity, target: *Entity) void {
    var damage = source.component.fighter.power - target.component.fighter.defense;
    if (damage > 0) {
        std.debug.print("{} attacks {} for {d} damage.\n", .{
            source.name, target.name, damage
        });
        target.component.fighter.setHp(target.component.fighter.hp-damage);
        if (target.component.fighter.hp == 0) {
            ent.die(target);
        }
    } else {
        std.debug.print("{} attacks {} but does no damage.\n", .{
            source.name, target.name
        });
    }
}