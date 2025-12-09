# Part 6: Doing and taking damage

## Refactoring

The first section of part 6 in the tutorials is a refactoring of the code. One of the major aspects of this refactoring is moving the engine reference and the event handler function. Since I'm working with Zig, a language that doesn't have object inheritance -- out of the box at least, among other considerations, I'm going to skip all of the refactoring in the tutorial. I have already departed enough from the tutorial architecture that I don't think it makes sense to carry out the same reorganization here. I do think my code needs some refactoring but I think I need to follow a different set of tradeoffs.

### Current assessment

```
main.zig               | system entry point; creates root console, player, dungeon, engine; begins game
constants.zig          | program-wide constants
models.zig             | data structures and tightly associated functions
tcod.zig               | libtcod interface facade
entity_factories.zig   | functions to create entities like the player, orc, and troll
engine.zig             | rendering and event handling
actions.zig            | encapsulates performing actions due to events
procgen.zig            | dungeon generation and entity placement
```

`main.zig`: Not really a fan of having so much initialization inside the system entry function. I think it makes sense to move much of the initialization to their own respective modules and keep only a bare bones function in here that starts everything off. At the moment I don't think I fully understand what the responsibility of the Engine is supposed to be but my sense is that the game loop should be there instead of here.
- _TODO: move tcod console initialization to `tcod.zig`_
- _TODO: move the game loop to the engine_

`constants.zig`: I'm going to leave this file mostly as-is for now because I think at some point pulling these configuration values out into an external file, perhaps a JSON or YAML, makes more sense than having them as program constants.
- _TODO: remove the ascii constant for the `@` symbol since it's not needed_

`models.zig`: When I started the tutorial I had no idea how many data structures I would need and how many modules might be needed to house them. At this point I think at least the game map is starting to grow enough to warrant it's own module. Potentially the same for the others. One thing I'll need to decide is: Do I want to continue having the models separate from their primary use code or should they be closer together? For example, should the action structures instead be in `actions.zig`? What are the pros and cons of separating them like I have here?
- _TODO: move game map into it's own module `map.zig`_
- _TODO: move color into it's own module `color.zig`_
- _TODO: move action structures to `actions.zig`_
- _TODO: move entity to it's own module, probably combined with `entity_factories` for now_
- _TODO: remove `models.zig`_

`tcod.zig`: I don't see any reason to change this. I need to keep a single point in the program for the libtcod `cImport` and place to wrap/alias all interaction with the external library and this continues to make sense to me as a place for that to happen.
- `renderMap`: One function in this module that I think may not belong is the render map function. The reason this is here is because rendering using the C API required knowledge of the inside of the libtcod `TCOD_Console` struct. At the time I wrote this it ended up in `tcod.zig` for lack of a better place. I'm starting to think possibly a _renderer_ module of some kind might make sense instead. A module that wraps all complex drawing of data structures out to the libtcod library system.
    - _TODO: create a renderer module_

`entity_factories.zig`: I see this as really temporary. In the future I think creation of entities should be file/data-driven and generic instead. Going to leave this alone for now in anticipation of later refactoring.

`engine.zig`: What is this structure and it's associated functions supposed to be for? What are it's responsibilities? Without doing much research on the subject I'm thinking this is where the game's core system and timing should be: event dispatch, game loop, calls to renderer, probably eventually scheduling. Going to mostly leave this alone. I could move `evKeydown` into an event handler but I'm going to wait a bit longer to see what the needs are related to that. Right now I only have a couple event functions so it's not causing any unnecessary burden yet.
- _TODO: move the key-related utility function to `tcod.zig` since they're very much like other tcod interface functions_
- _TODO: get rid of the use of system constants here and instead rely on values stored in the provided data structures_

`actions.zig`: I like this module the way it is. Well encapsulated. I'm not thrilled about passing an engine reference down into an action handler so I may try to lift this out and replace it with something else instead.
- _TODO: possibly lift out direct engine references_

`procgen.zig`: Going to leave this alone for now and see how the rest of the tutorial goes. If it remains mostly encapsulated I'll just leave it. One thing I may do is pull the `Coord` data structure out and make that more common. I don't like all the places in the application passing around x and y coordinates with their `i32` type attached. I think passing around a coordinate pair more places makes more sense.
- _TODO: possibly lift `Coord` out to a better common location_

**Overall**: Taking stock of where I'm at I see lots of little tactical improvments...
- _TODO: work on having less concrete `i32`-type data types all over the place_
- _TODO: more tests! these have proven invaluable to making sure things aren't broken before I fuss with rerunning the app_
- _TODO: work more on error handling; I'm ignoring a lot of possible errors and just throwing `try` everywhere to make things work rather than thinking more in depth about how a function can and should be used and what error it might return; some custom errors would be good_
- _TODO: stop using `undefined` as much, it just leads to trouble_
- _TODO: build something in front of Zig's random so that I can more concisely get random numbers in ranges I need for this particular app_
- _TODO: how the heck do I make better use of integers as array indexes? am I supposed to be int-casting them?_

Also... I keep hearing my laptop fan spin up while the game is running. Is there any way to limit the FPS and running speed?

### Refactored

```
actions.zig   | game actions and data structures
color.zig     | colors and color functions
constants.zig | global constants
engine.zig    | game loop and event handler
entity.zig    | entity structure and factories
main.zig      | system entry point
map.zig       | map, coord, tile structures and functions
procgen.zig   | dungeon generator
renderer.zig  | renderer function and map renderer
tcod.zig      | libtcod interface
```

## Callback functions from C

As part of part 6 one of the things I needed to figure out was pathfinding. It's possible to call a libtcod function and pass in a libtcod Map structure but this limits what can influence pathfinding, especially the presence of blocking entities, weather, other aspects that slow down movement through a cell or block a cell of the map.

Another way to do pathfinding is by calling a libtcod function and providing a callback. During libtcod processing the callback function is called repeatedly to check for the cost of a particular map location. This is the method I chose to use and it provided a use case for callback functions in Zig called from C. Here's what that looks like:

```zig
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

...

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
```

The `pathFunction` function is a Zig functon that takes `c_int`s for x/y from and x/y destination as well as a generic "user data" pointer. This pointer needs to be `anyopaque` because it can be anything (a C void pointer). It's also optional. The function returns a float that represents the cost in the graph for pathfinding through the given map cells. Since this function is going to be called from C we also need the `callconv(.C)` to set the calling convention, which tells how arguments and return values are handled in registers and things.

The second chunk of code creates a wrapper struct I call the `PathContext` and provide this along with the path function to the libtcod function to create a new path using a callback function. The path context is the `anyopaque` described earlier. I just send in the address to it and it's up to me in the path function to cast that generic pointer back to a path context.

After the setup is done and the path machinery is created I call the function to compute the path and can then "walk" each coordinate in it.

Notice that we only use the "next" coordinate in the path here rather than the whole thing. The reason is we're just getting a monster's next destination cell during their turn. Once this is done and the move takes place the function continues on to other work and deletes the path. Next turn we'll create a new path targetting the player and get a little closer.

## Entity

One major aspect of part 6 is the creation of `Actor` in the tutorial. Actor is a child class of `Entity` and adds some additional functionality. Zig lacks structure inheritance so I needed to handle this differently.

We also need to handle the `Fighter` component, another object hierarchy, render order, and AI code. Things that also take advantage of object-orientation in the tutorial. Again, no objects in Zig, at least not unless I write an object system.

So what to do? 

I solved this problem by adding some more to the `Entity` structure and using tagged unions like I did with actions:

```zig
pub const Entity = struct {
    x: i32 = 0,
    y: i32 = 0,
    glyph: u8 = '?',
    color: tcod.TcodColorRGB = color.rgb(255,255,255),
    name: []const u8 = "Unnamed",
    blocksMovement: bool = false,
    component: ComponentType = null,
    ai: ?ai.AIType = null, // optional ai
    isPlayer: bool = false,
    renderOrder: RenderOrder = RenderOrder.corpse,
};
```

This is my new entity structure. I have added `ComponentType`, `AIType`, and `RendererOrder` variables here. I think any entity can have an ai rather than just actors so why not just put it at the top here. It could go inside the component if that makes more sense later on. `ai` is an optional variable and for anything that doesn't use an AI system it'll just be null.

`ComponentType` is quite similar to the way I laid out actions and `RendererOrder` is just an enum:

```zig
pub const ComponentTag = enum {
    fighter,
};

pub const ComponentType = union(ComponentTag) {
    fighter: ComponentFighter,
};

pub const RenderOrder = enum {
    corpse,
    item,
    actor,
};
```

I'll be adding more types of components later on. Zig has interfaces sortof but for now I quite like using unions to represent heterogenous lists. This will allow me to have an array of component types on a future entity structure. For now I just have one to store the fighter component, which has hp and can die.

The actual `Fighter` component looks much like the one in the tutorial so I won't reproduce it here.

## Render order entities (sorting)

Here's a quick sort example I'm using to sort my array of entities by their render order:

```zig
pub fn getRenderOrderedEntities(self: *Map) []*Entity {
    var ents = self.entities.clone() catch @panic("failed");
    var entslice = ents.toOwnedSlice();
    ents.deinit();
    std.sort.sort(*Entity, entslice, {}, ent.renderOrderComparator);
    return entslice;
}

...

pub fn renderOrderComparator(context: void, a: *Entity, b: *Entity) bool {
    _ = context;
    return @enumToInt(a.renderOrder) < @enumToInt(b.renderOrder);
}
```

Not great error handling but it works. I find as my time available to work on the tutorial dwindles against other priorities I find myself taking shortcuts. Hopefully I will improve these things in the future.

I clone the arraylist of entities and get a new owned slice before sorting it. We cannot sort within the arraylist itself, at least I got an error when I tried that.

The actual sorting is easy given a comparator function.

## Console printing

The last thing I want to cover on part6, which took me way longer than I expected, was console printing. I just could not find a way to send a C function a heap allocated string when the C function was expecting a `const char *`. 

The libtcod function `TCOD_console_printf` function has the following signature:

```c
TCODLIB_API TCODLIB_FORMAT(4, 5) TCOD_Error
    TCOD_console_printf(TCOD_Console* __restrict con, int x, int y, const char* fmt, ...)
```

That `const char* fmt` is what gave me the issue. I am allocating a new formatted string in Zig resulting in a `[]u8`, which I just couldn't seem to get into a form this function could use. Casting the slice pointer to a `[*.c]const u8` (string literal) doesn't error but prints nothing. Still have no idea how to handle this.

I should say it works fine when you do provide an actual string literal, just not one allocated during runtime.

The other issue here is the varargs, which aren't really well supported in Zig. You can call them directly but what I wanted was to build up an array or struct of arguments to then pass along to this. In Java you'd do that with an array. In other languages you'd maybe use a spread operator. No idea here.

In the end I built my own print function and call it using an allocated string:

```zig
pub fn consolePrint(console: TcodConsole, x: i32, y: i32, fmt: []u8) void {
    var xi: i32 = 0;
    for (fmt) |ch| {
        consolePutCharEx(console, x+xi, y, ch, TcodColorRGB{.r=255,.g=255,.b=255}, 
            TcodColorRGB{.r=0,.g=0,.b=0});
        xi += 1;
    }
}

...

var msg = std.fmt.allocPrint(m.allocator, "hp: {d}/{d}", 
    .{player.component.fighter.hp, player.component.fighter.maxHp}) catch @panic("eom");
tcod.consolePrint(console, 1, 47, msg);
m.allocator.free(msg);
```

This `consolePrint` function just takes a `[]u8` array and prints all the characters to the console starting at the provided coordinates going left to right. I have no protection for going off the map at this point, which might be useful in the future, along with changing colors etc.

## Conclusion

Screenshot of [the new stuffs](images/dead_monsters.png).