//! zig-roguelike, by @anotherlehner

const std = @import("std");
const color = @import("color.zig");
const ent = @import("entity.zig");
const tcod = @import("tcod.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Entity = ent.Entity;
const expect = std.testing.expect;

pub const Coord = struct {
    x: i32,
    y: i32,

    pub fn eql(self: Coord, other: Coord) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub const Tile = struct {
    transparent: bool = false,
    walkable: bool = false,
    visible: bool = false,
    explored: bool = false,
    light: color.Graphic,
    dark: color.Graphic,
};

pub const FLOOR = Tile{ .walkable = true, .transparent = true, 
    .dark = color.Graphic{ .ch = ' ', .fg = color.White, .bg = color.SoftBlue },
    .light = color.Graphic{ .ch=' ', .fg=color.White, .bg = color.rgba(200,180,50,255)},
};

pub const WALL = Tile{ 
    .dark = color.Graphic{ .ch = ' ', .fg = color.White, .bg = color.DarkBlue },
    .light = color.Graphic{ .ch=' ', .fg=color.White, .bg=color.rgba(130,110,50,255)}
};

pub const Map = struct {
    width: i32,
    height: i32,
    cells: []Tile,
    tcMap: tcod.TcodMap = undefined,
    allocator: Allocator,
    entities: ArrayList(*Entity),

    pub fn addEntity(self: *Map, entity: *Entity, allocator: Allocator) !void {
        try self.entities.append(allocator, entity);
    }

    pub fn idx(self: *Map, x: i32, y: i32) usize {
        return @intCast(self.width * y + x);
    }

    pub fn inBounds(self: *Map, x: i32, y: i32) bool {
        return 0 <= x and x < self.width and 0 <= y and y < self.height and self.idx(x,y) < self.width * self.height;
    }

    pub fn fill(self: *Map, tileToFill: Tile) void {
        var i: i32 = 0;
        while (i < self.width * self.height) : (i += 1) {
            self.cells[@intCast(i)] = tileToFill;
        }
        tcod.mapClear(self.tcMap, tileToFill.transparent, tileToFill.walkable);
    }

    pub fn set(self: *Map, x: i32, y: i32, tileToSet: Tile) void {
        if (!self.inBounds(x,y)) std.debug.panic("outside of map: {d},{d}\n", .{x,y});
        self.cells[self.idx(x,y)] = tileToSet;
        tcod.mapSetProperties(self.tcMap, x, y, tileToSet.transparent, tileToSet.walkable);
    }

    pub fn deinit(self: *Map, allocate: Allocator) void {
        self.allocator.free(self.cells);
        for (self.entities.items) |e| {
            self.allocator.destroy(e);
        }
        self.entities.deinit(allocator);
    }

    pub fn get(self: *Map, x: i32, y: i32) *Tile {
        if (!self.inBounds(x,y)) @panic("outside of map");
        return &self.cells[self.idx(x,y)];
    }

    pub fn isInFov(self: *Map, x: i32, y: i32) bool {
        return tcod.mapIsInFov(self.tcMap, x, y);
    }

    pub fn isWalkable(self: *Map, x: i32, y: i32) bool {
        if (!self.inBounds(x,y)) return false;
        return self.cells[self.idx(x,y)].walkable;
    }

    pub fn getBlockingEntity(self: *Map, x: i32, y: i32) ?*Entity {
        for (self.entities.items) |i| {
            if (i.x == x and i.y == y and i.blocksMovement) {
                return i;
            }
        }
        return null;
    }

    pub fn isBlocked(self: *Map, x: i32, y: i32) bool {
        if (self.getBlockingEntity(x,y)) |_| {
            return true;
        }
        return false;
    }

    pub fn init(width: i32, height: i32, allocator: Allocator) !Map {
        const size = width * height;
        const cells = try allocator.alloc(Tile, @intCast(size));
        const ents: ArrayList(*Entity) = .empty;
        var m = Map{.width=width, .height=height, .allocator=allocator, .cells=cells, .entities=ents};
        m.tcMap = tcod.mapNew(width, height);
        m.fill(WALL);
        return m;
    }

    pub fn getRenderOrderedEntities(self: *Map) []*Entity {
        var ents = self.entities.clone() catch @panic("failed");
        var entslice = ents.toOwnedSlice();
        ents.deinit();
        std.sort.sort(*Entity, entslice, {}, ent.renderOrderComparator);
        return entslice;
    }
};

test "map.init" {
    var m = try Map.init(10, 10, std.testing.allocator);
    defer _ = m.deinit();
    try expect(m.cells.len > 0);
}

test "map.inBounds" {
    var m = Map{ .width = 10, .height = 10, .allocator=undefined, .cells = undefined, .entities=undefined };
    try expect(m.inBounds(0, 0));
    try expect(m.inBounds(5, 5));
    try expect(!m.inBounds(-1, -1));
    try expect(!m.inBounds(10, 10));
    try expect(!m.inBounds(20, 20));
}

test "map.inBounds2" {
    var m = Map{ .width = 40, .height = 25, .allocator=undefined, .cells = undefined, .entities=undefined };
    try expect(m.inBounds(39, 24));
}

test "map.fill should fill all cells with the same kind" {
    var m = try Map.init(2, 2, std.testing.allocator);
    defer _ = m.deinit();
    m.fill(WALL);
    try expect(std.meta.eql((m.get(0,0)).*, WALL));
    try expect(std.meta.eql((m.get(0,1)).*, WALL));
    try expect(std.meta.eql((m.get(1,0)).*, WALL));
    try expect(std.meta.eql((m.get(1,1)).*, WALL));
}