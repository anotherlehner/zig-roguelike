//! zig-roguelike, by @trymartinlehner

const std = @import("std");
const models = @import("models.zig");
const Allocator = std.mem.Allocator;

pub fn orc(x: i32, y: i32, allocator: Allocator) !*models.Entity {
    const e = try allocator.create(models.Entity);
    e.x = x;
    e.y = y;
    e.glyph='o';
    e.color = models.rgb(63,127,63);
    e.name="Orc";
    e.blocksMovement = true;
    return e;
}

pub fn troll(x: i32, y: i32, allocator: Allocator) !*models.Entity {
    const e = try allocator.create(models.Entity);
    e.x = x;
    e.y = y;
    e.glyph = 'T';
    e.color = models.rgb(0,127,0);
    e.name="Troll";
    e.blocksMovement = true;
    return e;
}

pub fn player(x: i32, y: i32, allocator: Allocator) !*models.Entity {
    const e = try allocator.create(models.Entity);
    e.x = x;
    e.y = y;
    e.glyph = '@';
    e.color = models.rgb(255,255,255);
    e.name = "Player";
    e.blocksMovement = true;
    return e;
}