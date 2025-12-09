# Part 4: Field of view

## Map changes

To implement field of view I had to make one major change to the way my code was organized: I needed to start using a C struct from libtcod called `TCOD_map_t` to store my map for field of view. Instead of changing a whole bunch of things and trying to get rid of my own map struct I decided to simply store a `TCOD_map_t` in my map struct and manage it internal to the map. This way the callers using the map don't have to interact directly with the tcod map structure and instead get the nice facade of Zig functions instead.

```zig
pub const TcodMap = c.TCOD_map_t;

pub const Map = struct {
    width: i32,
    height: i32,
    cells: []Tile,
    tcMap: tcod.TcodMap = undefined,
    allocator: Allocator,

    ...
}
```

In places where I'm managing the `cells` array of Tiles I also set the same values on the transparent and walkable properties of the `TcodMap`. Example:

```zig
pub fn set(self: *Map, x: i32, y: i32, tileToSet: Tile) void {
    if (!self.inBounds(x,y)) std.debug.panic("outside of map: {d},{d}\n", .{x,y});
    self.cells[self.idx(x,y)] = tileToSet;
    tcod.mapSetProperties(self.tcMap, x, y, tileToSet.transparent, tileToSet.walkable);
}
```

At the moment this is a bit inefficient since I'm mirroring the same `walkable` and `transparent` properties on my own `Tile` structures. I'm looking to get rid of that in the future and somehow eliminate that redundancy. For now it works.

## Computing FOV

Now that I have a `TCOD_map_t` structure I create it using a function in libtcod and fill it up with the same values that my tiles already have. Computing the field of view is now very straightforward:

```zig
pub fn computeFov(map: TcodMap, povX: i32, povY: i32) void {
    _ = c.TCOD_map_compute_fov(map, povX, povY, 8, true, c.FOV_BASIC);
}
```

This simple function takes the x and y position for the center of the field of view and a `TcodMap` (which is an alias for `TCOD_map_t`). Here I call the C function provided by libtccod and give it a few extra params for radius size, type of field of view calculation, etc.

I then added this to my engine function:

```zig
pub fn handleEvents(self: *Engine) void {
    ...
    tcod.computeFov(self.map.tcMap, self.player.x, self.player.y);
}
```

All that remains is to update the renderer...

## Rendering the FOV

Before this part 4 code I was rendering the tiles to the console by simply going through the long single-dimensional array of tiles and transferring all the tile and graphic data to the libtcod console. Very simple. Now I have the extra `TCOD_map_t` and it's own libtcod functions to work with it so I modified it to work with both:

```zig
pub fn renderMap(console: TcodConsole, map: *models.Map) void {
    var x: i32 = 0;
    var y: i32 = 0;
    for (map.cells) |t, index| {
        if (mapIsInFov(map.tcMap, x, y)) {
            map.cells[index].visible = true;
            map.cells[index].explored = true;
        } else {
            map.cells[index].visible = false;
        }

        if (t.visible) {
            console.tiles[index].ch = t.light.ch;
            console.tiles[index].fg = t.light.fg;
            console.tiles[index].bg = t.light.bg;
        } else if (t.explored) {
            console.tiles[index].ch = t.dark.ch;
            console.tiles[index].fg = t.dark.fg;
            console.tiles[index].bg = t.dark.bg;
        } else {
            console.tiles[index].ch = models.SHROUD.ch;
            console.tiles[index].fg = models.SHROUD.fg;
            console.tiles[index].bg = models.SHROUD.bg;
        }

        x += 1;
        if (@mod(x,map.width) == 0) {
            y += 1;
            x = 0;
        }
    }
}
```

Some comments:
- I'm using x/y variables to create the coordinates I need to call libtcod function `TCOD_map_is_in_fov`, which requires coordinates
- First I check if the coordinate is in the FOV and set the `visible` and `explored` flags on the particular tile
- For each tile render a set of ch/fg/bg depending on whether the tile is visible in the field of view, outside the field of view but already explored, or never seen before

## Conclusion

With part 4 done a new screenshot is born: [screenshot](images/fov.png).