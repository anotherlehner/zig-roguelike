# Part 3

Encountered a lot of challenges doing this part...

## Random

In Zig, to create random integers we need to use the `std.rand` namespace struct `DefaultPrng`. This is the default pseudorandom number generator. It's a little odd at first because you make a `DefaultPrng` struct and then access the random functions through an embedded interface. Here's what that looks like:

```zig
// import
const RndGen = std.rand.DefaultPrng;

// initialize the randome generator
var rnd = RndGen.init(0);

// seed the random generator using the current time
rnd.seed(@intCast(u64, std.time.milliTimestamp()));

// get a random i32 integer between room min and max size (at most means this is inclusive of room max size)
const roomWidth = rnd.random().intRangeAtMost(i32, room_min_size, room_max_size);
```

The part where I do `rnd.random().intRangeAtMost...` is the weird part for me. Usually the interface is something you pass around and call to get into the implementation underneath. This seems like it's reversed? I'd like to work on understanding this more and then try to setup something similar in my own structs.

## ArrayList

I think this part is the first where I used an `ArrayList`. I used this structure in this part for making lists (slices) of coordinates to pass around and iterate over.

Here's one example:

```zig
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
```

This could use some refactoring but it's an example... For any rectangular room we want to be able to get the inner parts as a list of coordinates that can then be "carved out" of the map by setting those cells to be floor instead of wall.

It's really important to remember to defer the `deinit` call here after creating the array list so that it gets de-initialized when the function exits.

The final call to `toOwnedSlice()` creates a slice pointing to all the elements we created that can be iterated over by the caller of this function. The caller also needs to remember to free the owned slice so we avoid a memory leak! Here's the bit that uses this code:

```zig
var roomInner = try room.inner(allocator);
defer allocator.free(roomInner);
for (roomInner) |coord| {
    map.set(coord.x, coord.y, models.FLOOR);
}
```

## Lines

The last thing I want to mention here in this summary of part 3 is line creation. The libtcod library has some functionality to create lines of x/y coordinates using the Bresenham algorithm. The C API has a couple different sets of functions to do this and I think I used deprecated functions but either way...

```zig
pub fn line(start: Coord, end: Coord, innerList: *ArrayList(Coord)) !void {
    if (start.eql(end)) {
        // Only seems to happen because a corner wasn't needed
        std.log.info("line: zero length line sequence {s} == {s}", .{start,end});
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
```

* The function takes start, end coordinates and an array list to add the resulting coordinates to
* I learned after a couple hours of debugging that my function here will not behave well if given a start and end that are equal (it needs refactoring) and for now I added a simple check to see if start/end were equal and return if so
* The addresses of the integers `x` and `y` are given to the `lineStep` function, which internally calls the libtcod line step function, which itself puts the _next_ coordinate pair of x/y directly into the memory addresses
* Finally I loop until `lineStep` returns false and the line ends

I will try to improve this for the future and try putting the x/y memory address variable inside my `tcod.lineStep` function instead of exposing that machinery here. Another good improvement would be to stop swallowing the first `lineStep` result and actually check for it. This code assumes we always will have at least 1 cell to cover but that seems to have been a misplaced assumption.

Update: I actually found this interesting:

```zig
var x: i32 = undefined;
var y: i32 = undefined;
tcod.lineInit(1, 1, 1, 1); // start: 1,1 and end: 1,1 (0 length line)
var firstStep = tcod.lineStep(&x, &y);
```

I would think firstStep should return `false` here because the line is 0 cells long and shouldn't set anything in x and y. Indeed nothing it set in x or y and they just have garbage in them. Unfortunately `lineStep` here returned `true` and my loop, which followed these lines, just kept going -- and blew up. Really seems like that should return false, but maybe that's one reason why it's deprecated? I should try the other functions available for drawing lines.

## Conclusion

You can see all the updated code in the src folder for this part. I think discussing things I found interesting, new, or problematic and putting aside trying to develop a full blown tutorial here is helping with time. Perhaps when I'm done with all thirteen parts (cross fingers) I'll come back and rewrite all these readmes into a full Zig roguelike tutorial... if someone doesn't beat me to it first.

:)

picture of basic rooms with tunnel in between: [screenshot](images/basic_rooms.png)

closing picture of the dungeon: [screenshot](images/dungeon.png)