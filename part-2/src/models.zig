//! zig-roguelike, by @anotherlehner

const std = @import("std");
const constants = @import("constants.zig");
const tcod = @import("tcod.zig");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

// Structs for the available action types
pub const EscapeAction = struct {};
pub const MoveAction = struct { dx: i32, dy: i32 };

// This enum is used to create a tagged union of actions
pub const ActionTypeTag = enum {
    escapeAction,
    moveAction,
};

// Action type union; this structure can only have 1 active union value at a time
// and can be used in switch statements!
pub const ActionType = union(ActionTypeTag) {
    escapeAction: EscapeAction,
    moveAction: MoveAction,
};

pub const Color_Red = tcod.TcodColorRGBA{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const Color_Black = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const Color_White = tcod.TcodColorRGBA{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const Color_SoftBlue = tcod.TcodColorRGBA{ .r = 50, .g = 50, .b = 150, .a = 255 };
pub const Color_DarkBlue = tcod.TcodColorRGBA{ .r = 0, .g = 0, .b = 100, .a = 255 };

// Entity -- things that go bump in the night
pub const Entity = struct {
    x: i32,
    y: i32,
    glyph: u8,
    color: tcod.TcodColorRGB,

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

// Tile
pub const Tile = struct {
    walkable: bool,
    transparent: bool,
    dark: Graphic,
};

pub const FLOOR = Tile{ .walkable = true, .transparent = true, .dark = Graphic{ .ch = ' ', .fg = Color_White, .bg = Color_SoftBlue } };
pub const WALL = Tile{ .walkable = false, .transparent = false, .dark = Graphic{ .ch = ' ', .fg = Color_White, .bg = Color_DarkBlue } };

// Map
pub const Map = struct {
    width: i32,
    height: i32,
    allocator: Allocator,
    tiles: []Tile, // width * height

    pub fn inBounds(self: *Map, x: i32, y: i32) bool {
        return 0 <= x and x < self.width and 0 <= y and y < self.height;
    }

    pub fn fill(self: *Map, tileToFill: Tile) void {
        var i: i32 = 0;
        while (i < self.width * self.height) : (i += 1) {
            self.tiles[@intCast(usize,i)] = tileToFill;
        }
    }

    pub fn deinit(self: *Map) void {
        self.allocator.free(self.tiles);
    }

    pub fn get(self: *Map, x: i32, y: i32) !*Tile {
        if (!self.inBounds(x,y)) {
            @panic("went outside of map");
        }
        return &self.tiles[@intCast(usize, (self.width*x)+y)];
    }

    pub fn isWalkable(self: *Map, x: i32, y: i32) bool {
        if (!self.inBounds(x,y)) return false;
        var loc = (self.width * y) + x;
        if (loc > self.width * self.height) {
            std.log.info("outside map bounds, x: {d}, y: {d}, loc: {d}, mapsize: {d}", .{x,y, loc,(self.width*self.height)});
            @panic("went outside of map");
        }
        return self.tiles[@intCast(usize, loc)].walkable;
    }

    pub fn init(width: i32, height: i32, allocator: Allocator) !Map {
        const size = width * height;
        var tiles = try allocator.alloc(Tile, @intCast(usize, size));
        var m = Map{.width=width, .height=height, .allocator=allocator, .tiles=tiles};
        m.fill(FLOOR);
        return m;
    }

    pub fn addSomeWalls(self: *Map) void {
        self.tiles[200] = WALL;
        self.tiles[201] = WALL;
        self.tiles[505] = WALL;
        self.tiles[550] = WALL;
    }
};

test "map.init" {
    var m = try Map.init(10, 10, std.testing.allocator);
    defer _ = m.deinit();
    try expect(m.tiles.len > 0);
}

test "map.inBounds" {
    var m = Map{ .width = 10, .height = 10, .allocator=undefined, .tiles = undefined };
    try expect(m.inBounds(0, 0));
    try expect(m.inBounds(5, 5));
    try expect(!m.inBounds(-1, -1));
    try expect(!m.inBounds(10, 10));
    try expect(!m.inBounds(20, 20));
}

test "map.fill should fill all tiles with the same kind" {
    var m = try Map.init(2, 2, std.testing.allocator);
    defer _ = m.deinit();
    m.fill(WALL);
    try expect(std.meta.eql((try m.get(0,0)).*, WALL));
    try expect(std.meta.eql((try m.get(0,1)).*, WALL));
    try expect(std.meta.eql((try m.get(1,0)).*, WALL));
    try expect(std.meta.eql((try m.get(1,1)).*, WALL));
}