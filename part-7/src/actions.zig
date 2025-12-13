//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const ent = @import("entity.zig");
const map = @import("map.zig");
const engine = @import("engine.zig");
const color = @import("color.zig");

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
        ActionType.bumpAction => |b| performBumpAction(eng, b),
        ActionType.waitAction => performWaitAction(),
    }
}

pub fn performWaitAction() void {
    // TODO: log
}

pub fn performEscapeAction(eng: *engine.Engine) void {
    std.log.info("EscapeAction: quitting", .{});
    eng.quit();
}

pub fn performBumpAction(eng: *engine.Engine, bump: BumpAction) void {
    const nx = eng.player.x + bump.dx;
    const ny = eng.player.y + bump.dy;
    if (eng.map.getBlockingEntity(nx, ny)) |target| {
        if (target.component == ent.ComponentType.fighter) {
            performMeleeAction(eng, eng.player, target);
        }
    } else {
        performMoveAction(eng.map, eng.player, nx, ny);
    }
}

pub fn performMoveAction(m: *Map, entity: *Entity, nx: i32, ny: i32) void {
    if (m.isWalkable(nx, ny)) {
        entity.x = nx;
        entity.y = ny;
    }
}

pub fn performMeleeAction(eng: *engine.Engine, source: *Entity, target: *Entity) void {
    const damage = source.component.fighter.power - target.component.fighter.defense;
    const attackColor = if (source.isPlayer) color.Player_atk else color.Enemy_atk;
    if (damage > 0) {
        const msg = std.fmt.allocPrint(eng.allocator, "{s} attacks {s} for {d} damage", .{ source.name, target.name, damage }) catch @panic("eom");
        eng.log.addMessage(msg, attackColor, true);
        target.component.fighter.setHp(target.component.fighter.hp - damage);
        if (target.component.fighter.hp == 0) {
            ent.die(eng, target);
        }
    } else {
        const msg = std.fmt.allocPrint(eng.allocator, "{s} attacks {s} but does no damage", .{ source.name, target.name }) catch @panic("eom");
        eng.log.addMessage(msg, attackColor, true);
    }
}
