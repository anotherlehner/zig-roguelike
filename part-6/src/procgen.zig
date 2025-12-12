//! zig-roguelike, by @anotherlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const ent = @import("entity.zig");
const map = @import("map.zig");
const RndGen = std.rand.DefaultPrng;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Map = map.Map;
const Coord = map.Coord;
const Entity = ent.Entity;
const expect = std.testing.expect;

pub const RectangularRoom = struct {
    x1: i32,
    y1: i32,
    x2: i32,
    y2: i32,

    pub fn center(self: RectangularRoom) Coord {
        return Coord{
            .x = @divTrunc(self.x1 + self.x2, 2),
            .y = @divTrunc(self.y1 + self.y2, 2),
        };
    }

    pub fn inner(self: RectangularRoom, allocator: Allocator) ![]Coord {
        var innerList = ArrayList(Coord).init(allocator);
        defer innerList.deinit();
        var xi: i32 = self.x1 + 1;
        while (xi < self.x2) : (xi += 1) {
            var yi: i32 = self.y1 + 1;
            while (yi < self.y2) : (yi += 1) {
                try innerList.append(.{ .x = xi, .y = yi });
            }
        }
        return innerList.toOwnedSlice();
    }

    pub fn init(x: i32, y: i32, width: i32, height: i32) RectangularRoom {
        var r = RectangularRoom{
            .x1 = x,
            .y1 = y,
            .x2 = width + x,
            .y2 = height + y,
        };
        return r;
    }

    pub fn intersects(self: RectangularRoom, other: RectangularRoom) bool {
        return self.x1 <= other.x2 and self.x2 >= other.x1 and self.y1 <= other.y2 and self.y2 >= other.y1;
    }
};

pub fn placeEntities(room: *RectangularRoom, m: *Map, maxMonsters: i32, allocator: Allocator) !void {
    var rnd = RndGen.init(0);
    rnd.seed(@intCast(u64, std.time.milliTimestamp()));

    var nMonsters = rnd.random().intRangeAtMost(i32, 0, maxMonsters);
    var i: usize = 0;
    while (i < nMonsters) {
        var x: i32 = rnd.random().intRangeAtMost(i32, room.x1+1, room.x2-1);
        var y: i32 = rnd.random().intRangeAtMost(i32, room.y1+1, room.y2-1);
        var monsterType = rnd.random().intRangeAtMost(i32, 1, 10);
        if (monsterType < 8) {
            try m.addEntity(try ent.orc(x,y, allocator));
        } else {
            try m.addEntity(try ent.troll(x,y, allocator));
        }
        i += 1;
    }
}

pub fn tunnelBetween(start: Coord, end: Coord, allocator: Allocator) ![]Coord {
    var rnd = RndGen.init(0);
    rnd.seed(@intCast(u64, std.time.milliTimestamp()));

    var innerList = ArrayList(Coord).init(allocator);
    defer innerList.deinit();

    var cornerX: i32 = undefined;
    var cornerY: i32 = undefined;
    if (rnd.random().intRangeAtMost(i32, 0, 1) == 0) {
        cornerX = end.x;
        cornerY = start.y;
    } else {
        cornerX = start.x;
        cornerY = end.y;
    }

    try line(start, .{.x=cornerX,.y=cornerY}, &innerList);
    try line(.{.x=cornerX,.y=cornerY}, end, &innerList);

    return innerList.toOwnedSlice();
}

pub fn line(start: Coord, end: Coord, innerList: *ArrayList(Coord)) !void {
    if (start.eql(end)) {
        // Only seems to happen because a corner wasn't needed
        // std.log.info("line: zero length line sequence {} == {}", .{start,end});
        return;
    }
    var x: i32 = undefined;
    var y: i32 = undefined;
    tcod.lineInit(start.x, start.y, end.x, end.y);
    _ = tcod.lineStep(&x, &y);
    try innerList.append(.{ .x = x, .y = y });
    while (!tcod.lineStep(&x, &y)) {
        try innerList.append(.{ .x = x, .y = y });
    }
}

pub fn generateDungeon(max_rooms: usize, room_min_size: i32, room_max_size: i32, room_max_monsters: i32, width: i32, height: i32, player: *Entity, allocator: Allocator) !Map {
    var m = try Map.init(width, height, allocator);
    try m.entities.append(player);

    var rooms = try allocator.alloc(RectangularRoom, max_rooms);
    defer allocator.free(rooms);
    
    var rnd = RndGen.init(0);
    rnd.seed(@intCast(u64, std.time.milliTimestamp()));

    var i: usize = 0;
    while (i < max_rooms) {
        const roomWidth = rnd.random().intRangeAtMost(i32, room_min_size, room_max_size);
        const roomHeight = rnd.random().intRangeAtMost(i32, room_min_size, room_max_size);

        const x = rnd.random().intRangeAtMost(i32, 0, width - roomWidth - 1);
        const y = rnd.random().intRangeAtMost(i32, 0, height - roomHeight - 1);

        var room = RectangularRoom.init(x,y,roomWidth, roomHeight);

        // intersections
        var j: usize = 0;
        var interscts: bool = false;
        while (j < i) : (j += 1) {
            if (room.intersects(rooms[j])) interscts = true;
        }

        if (!interscts) {
            // carve out the room insides
            var roomInner = try room.inner(allocator);
            defer allocator.free(roomInner);
            for (roomInner) |coord| {
                m.set(coord.x, coord.y, map.FLOOR);
            }

            if (i == 0) {
                const center = room.center();
                player.x = center.x;
                player.y = center.y;
            } else {
                var tunnelCoords: []Coord = try tunnelBetween(rooms[i-1].center(), room.center(), allocator);
                defer allocator.free(tunnelCoords);
                for (tunnelCoords) |c| {
                    m.set(c.x, c.y, map.FLOOR);
                }
            }

            try placeEntities(&room, &m, room_max_monsters, allocator);

            rooms[i] = room;
            i += 1;
        }
    }

    return m;
}

test "tunnelBetween" {
    var t = try tunnelBetween(.{.x=0,.y=0}, .{.x=5,.y=5}, std.testing.allocator);
    defer std.testing.allocator.free(t);
    try expect(t.len == 10);
    try expect(std.meta.eql(t[4], .{.x=0,.y=5}) or std.meta.eql(t[4], .{.x=5,.y=0}));
}

test "line" {
    var innerList = ArrayList(Coord).init(std.testing.allocator);
    defer innerList.deinit();
    try line(.{.x=0,.y=0}, .{.x=2,.y=2}, &innerList);
    try expect(innerList.items.len == 2);
    try expect(std.meta.eql(innerList.items[0], Coord{.x=1,.y=1}));
    try expect(std.meta.eql(innerList.items[1], Coord{.x=2,.y=2}));
}

test "rectangularroom.intersects true" {
    const r1 = RectangularRoom.init(3, 3, 5, 5);
    const r2 = RectangularRoom.init(1,1, 5, 5);
    try expect(r1.intersects(r2) == true);
}

test "rectangularroom.intersects false" {
    const r1 = RectangularRoom.init(1, 1, 5, 5);
    const r2 = RectangularRoom.init(8, 8, 5, 5);
    try expect(r1.intersects(r2) == false);
}

test "rectangularroom.init" {
    const rr = RectangularRoom.init(1, 2, 10, 8);
    try expect(rr.x1 == 1);
    try expect(rr.y1 == 2);
    try expect(rr.x2 == 11);
    try expect(rr.y2 == 10);
}

test "rectangularroom.center" {
    const rr = RectangularRoom.init(1, 1, 11, 11);
    const center = rr.center();
    try expect(center.x == 6);
    try expect(center.y == 6);
}

test "rectangularroom.inner" {
    const rr = RectangularRoom.init(1, 1, 3, 3);
    var inner = try rr.inner(std.testing.allocator);
    defer std.testing.allocator.free(inner);
    try expect(std.meta.eql(inner[0], Coord{ .x = 2, .y = 2 }));
    try expect(std.meta.eql(inner[1], Coord{ .x = 2, .y = 3 }));
    try expect(inner.len == 4);
}
