//! zig-roguelike, by @anotherlehner

const std = @import("std");
const constants = @import("constants.zig");
const tcod = @import("tcod.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

// Structs for the available action types
pub const EscapeAction = struct {};
pub const BumpAction = struct { dx: i32, dy: i32 };

// This enum is used to create a tagged union of actions
pub const ActionTypeTag = enum {
    escapeAction,
    bumpAction,
};

// Action type union; this structure can only have 1 active union value at a time
// and can be used in switch statements!
pub const ActionType = union(ActionTypeTag) {
    escapeAction: EscapeAction,
    bumpAction: BumpAction,
};

pub const Color_Red = tcod.TcodColorRGBA{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const Color_Black = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const Color_White = tcod.TcodColorRGBA{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const Color_SoftBlue = tcod.TcodColorRGBA{ .r = 50, .g = 50, .b = 150, .a = 255 };
pub const Color_DarkBlue = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 100, .a = 255 };

pub fn rgba(r: u8, g: u8, b: u8, a: u8) tcod.TcodColorRGBA {
    return tcod.TcodColorRGBA{.r = r, .g=g, .b=b, .a=a};
}

pub fn rgb(r: u8, g: u8, b: u8) tcod.TcodColorRGB {
    return tcod.TcodColorRGB{.r = r, .g = g, .b = b};
}

// Entity -- things that go bump in the night
pub const Entity = struct {
    x: i32 = 0,
    y: i32 = 0,
    glyph: u8 = '?',
    color: tcod.TcodColorRGB = rgb(255,255,255),
    name: []const u8 = "Unnamed",
    blocksMovement: bool = false,

    pub fn move(self: *Entity, dx: i32, dy: i32) void {
        self.x += dx;
        self.y += dy;
    }
};

// Graphic -- TCOD_ConsoleTile equivalent
pub const Graphic = struct {
    ch: u8,
    fg: tcod.TcodColorRGBA,
    bg: tcod.TcodColorRGBA,
};

pub const SHROUD = Graphic{.ch=' ', .fg=Color_White, .bg=Color_Black};

// Tile
pub const Tile = struct {
    transparent: bool = false,
    walkable: bool = false,
    visible: bool = false,
    explored: bool = false,
    light: Graphic,
    dark: Graphic,
};

pub const FLOOR = Tile{ .walkable = true, .transparent = true, 
    .dark = Graphic{ .ch = ' ', .fg = Color_White, .bg = Color_SoftBlue },
    .light = Graphic{ .ch=' ', .fg=Color_White, .bg = rgba(200,180,50,255)},
};
pub const WALL = Tile{ .dark = Graphic{ .ch = ' ', .fg = Color_White, .bg = Color_DarkBlue },
    .light = Graphic{ .ch=' ', .fg=Color_White, .bg=rgba(130,110,50,255)} };

// Map
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

    pub fn deinit(self: *Map, allocator: Allocator) void {
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
};

test "map.init" {
    var m = try Map.init(10, 10, std.testing.allocator);
    defer _ = m.deinit(std.testing.allocator);
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
    defer _ = m.deinit(std.testing.allocator);
    m.fill(WALL);
    try expect(std.meta.eql((m.get(0,0)).*, WALL));
    try expect(std.meta.eql((m.get(0,1)).*, WALL));
    try expect(std.meta.eql((m.get(1,0)).*, WALL));
    try expect(std.meta.eql((m.get(1,1)).*, WALL));
}
