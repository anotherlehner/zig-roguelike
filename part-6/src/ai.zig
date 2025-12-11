//! zig-roguelike, by @anotherlehner
const std = @import("std");
const ent = @import("entity.zig");
const map = @import("map.zig");
const tcod = @import("tcod.zig");
const action = @import("actions.zig");
const math = std.math;
const TcodPath = tcod.TcodPath;

pub const AITag = enum {
    hostile,
};

pub const AIType = union(AITag) {
    hostile: AIHostileEnemy,
};

pub fn act(source: *ent.Entity, target: *ent.Entity, aiType: AIType, mp: *map.Map) void {
    switch (aiType) {
        AIType.hostile => |hostile| hostile.act(source, target, mp),
    }
}

const PathContext = struct {
    mp: *map.Map,
    target: map.Coord,
};

/// C callback function for pathfinding
fn pathFunction(xFrom: c_int, yFrom: c_int, xTo: c_int, yTo: c_int, userData: ?*anyopaque) callconv(.C) f32 {
    var ctx = @ptrCast(*PathContext, @alignCast(@alignOf(*PathContext), userData.?));
    _ = xFrom;
    _ = yFrom;
    var isTarget = ctx.target.x == xTo and ctx.target.y == yTo;
    if (!isTarget and (!ctx.mp.isWalkable(xTo, yTo) or ctx.mp.isBlocked(xTo, yTo))) {
        // the way is blocked and have not reached target
        return 0.0;
    } else {
        // target or unblocked path
        return 1.0;
    }
}

const AIHostileEnemy = struct {
    pub fn act(self: AIHostileEnemy, source: *ent.Entity, 
            target: *ent.Entity, mp: *map.Map) void {
        _ = self;
        var absDx = math.absInt(target.x - source.x) catch unreachable;
        var absDy = math.absInt(target.y - source.y) catch unreachable;
        var distance = @maximum(absDx, absDy);
        if (mp.isInFov(source.x, source.y)) {
            if (distance <= 1) {
                action.performMeleeAction(source, target);
            } else {
                var ctx = PathContext{.mp=mp, .target=map.Coord{.x=target.x,.y=target.y}};
                var pathToTarget = tcod.pathNewUsingFn(mp.width, mp.height, pathFunction, &ctx);
                defer {
                    tcod.pathDelete(pathToTarget);
                }
                _ = tcod.pathCompute(pathToTarget, source.x, source.y, target.x, target.y);
                if (!tcod.pathIsEmpty(pathToTarget)) {
                    var destX: i32 = 0;
                    var destY: i32 = 0;
                    if (tcod.pathWalk(pathToTarget, &destX, &destY)) {
                        action.performMoveAction(mp, source, destX, destY);
                    }
                }
            }
        } else {
            action.performWaitAction();
        }
    }
};