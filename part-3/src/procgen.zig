//! zig-roguelike, by Martin Lehner (@anotherlehner)

const std = @import("std");
const models = @import("models.zig");
const tcod = @import("tcod.zig");
const RndGen = std.Random.DefaultPrng;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

const Coord = struct {
    x: i32,
    y: i32,

    pub fn eql(self: Coord, other: Coord) bool {
        return self.x == other.x and self.y == other.y;
    }
};

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
        var innerList: ArrayList(Coord) = .empty;
        defer innerList.deinit(allocator);
        var xi: i32 = self.x1 + 1;
        while (xi < self.x2) : (xi += 1) {
            var yi: i32 = self.y1 + 1;
            while (yi < self.y2) : (yi += 1) {
                try innerList.append(allocator, .{ .x = xi, .y = yi });
            }
        }
        return innerList.toOwnedSlice(allocator);
    }

    pub fn init(x: i32, y: i32, width: i32, height: i32) RectangularRoom {
        const r = RectangularRoom{
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

pub fn tunnelBetween(start: Coord, end: Coord, allocator: Allocator) ![]Coord {
    const now = try std.time.Instant.now();
    var rnd = RndGen.init(0);
    rnd.seed(@intCast(now.timestamp.sec));

    var innerList: ArrayList(Coord) = .empty;
    defer innerList.deinit(allocator);

    var cornerX: i32 = undefined;
    var cornerY: i32 = undefined;
    if (rnd.random().intRangeAtMost(i32, 0, 1) == 0) {
        cornerX = end.x;
        cornerY = start.y;
    } else {
        cornerX = start.x;
        cornerY = end.y;
    }

    try line(start, .{ .x = cornerX, .y = cornerY }, &innerList, allocator);
    try line(.{ .x = cornerX, .y = cornerY }, end, &innerList, allocator);

    return innerList.toOwnedSlice(allocator);
}

pub fn line(start: Coord, end: Coord, innerList: *ArrayList(Coord), allocator: Allocator) !void {
    if (start.eql(end)) {
        // Only seems to happen because a corner wasn't needed
        std.log.info("line: zero length line sequence {} == {}", .{ start, end });
        return;
    }
    var x: i32 = undefined;
    var y: i32 = undefined;
    tcod.lineInit(start.x, start.y, end.x, end.y);
    _ = tcod.lineStep(&x, &y);
    try innerList.append(allocator, .{ .x = x, .y = y });
    while (!tcod.lineStep(&x, &y)) {
        try innerList.append(allocator, .{ .x = x, .y = y });
    }
}

pub fn generateDungeon(max_rooms: usize, room_min_size: i32, room_max_size: i32, width: i32, height: i32, player: *models.Entity, allocator: Allocator) !models.Map {
    var map = try models.Map.init(width, height, allocator);

    var rooms = try allocator.alloc(RectangularRoom, max_rooms);
    defer allocator.free(rooms);

    const now = try std.time.Instant.now();
    var rnd = RndGen.init(0);
    rnd.seed(@intCast(now.timestamp.sec));

    var i: usize = 0;
    while (i < max_rooms) {
        const roomWidth = rnd.random().intRangeAtMost(i32, room_min_size, room_max_size);
        const roomHeight = rnd.random().intRangeAtMost(i32, room_min_size, room_max_size);

        const x = rnd.random().intRangeAtMost(i32, 0, width - roomWidth - 1);
        const y = rnd.random().intRangeAtMost(i32, 0, height - roomHeight - 1);

        var room = RectangularRoom.init(x, y, roomWidth, roomHeight);

        // intersections
        var j: usize = 0;
        var interscts: bool = false;
        while (j < i) : (j += 1) {
            if (room.intersects(rooms[j])) interscts = true;
        }

        if (!interscts) {
            // carve out the room insides
            const roomInner = try room.inner(allocator);
            defer allocator.free(roomInner);
            for (roomInner) |coord| {
                map.set(coord.x, coord.y, models.FLOOR);
            }

            if (i == 0) {
                const center = room.center();
                player.x = center.x;
                player.y = center.y;
            } else {
                const tunnelCoords: []Coord = try tunnelBetween(rooms[i - 1].center(), room.center(), allocator);
                defer allocator.free(tunnelCoords);
                for (tunnelCoords) |c| {
                    map.set(c.x, c.y, models.FLOOR);
                }
            }

            rooms[i] = room;
            i += 1;
        }
    }

    return map;
}

test "tunnelBetween" {
    const t = try tunnelBetween(.{ .x = 0, .y = 0 }, .{ .x = 5, .y = 5 }, std.testing.allocator);
    defer std.testing.allocator.free(t);
    try expect(t.len == 10);
    try expect(std.meta.eql(t[4], .{ .x = 0, .y = 5 }));
}

test "line" {
    var innerList: ArrayList(Coord) = .empty;
    defer innerList.deinit(std.testing.allocator);
    try line(.{ .x = 0, .y = 0 }, .{ .x = 2, .y = 2 }, &innerList, std.testing.allocator);
    try expect(innerList.items.len == 2);
    try expect(std.meta.eql(innerList.items[0], Coord{ .x = 1, .y = 1 }));
    try expect(std.meta.eql(innerList.items[1], Coord{ .x = 2, .y = 2 }));
}

test "rectangularroom.intersects true" {
    const r1 = RectangularRoom.init(3, 3, 5, 5);
    const r2 = RectangularRoom.init(1, 1, 5, 5);
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
    const inner = try rr.inner(std.testing.allocator);
    defer std.testing.allocator.free(inner);
    try expect(std.meta.eql(inner[0], Coord{ .x = 2, .y = 2 }));
    try expect(std.meta.eql(inner[1], Coord{ .x = 2, .y = 3 }));
    try expect(inner.len == 4);
}
