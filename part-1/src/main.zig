//! zig-roguelike, by Martin Lehner (@anotherlehner)
const std = @import("std");
const expect = std.testing.expect;

// translate and import the libtcod C and libSDL3 library headers
const c = @cImport({
    @cInclude("libtcod.h");

    // Unknown if this is a dangerous idea because I may be mixing namespaces?
    @cInclude("SDL3/SDL.h");
});

// using small values now because the resulting window is large and easy to see
const SCREEN_WIDTH = 40;
const SCREEN_HEIGHT = 25;

pub fn main() anyerror!void {
    var params = c.TCOD_ContextParams{
        .tcod_version = c.TCOD_COMPILEDVERSION,
        .columns = SCREEN_WIDTH,
        .rows = SCREEN_HEIGHT,
        .renderer_type = c.TCOD_RENDERER_SDL2,
        .vsync = 1,
        .window_title = "Zig Roguelike",
        .sdl_window_flags = c.SDL_WINDOW_RESIZABLE,
        .pixel_width = 800,
        .pixel_height = 600,
        .console = c.TCOD_console_new(40, 25),
        .tileset = c.TCOD_tileset_load("../dejavu10x10_gs_tc.png", 32, 8, 256, &c.TCOD_CHARMAP_TCOD)
    };

    var context: ?*c.TCOD_Context = null;
    _ = c.TCOD_context_new(&params, &context);
    defer { 
        // Make sure the quit function is called when main() exits
        c.TCOD_quit();
    }

    // Struct to hold key events when they occur to be processed
    var key = c.TCOD_key_t{ .vk = c.TCODK_NONE, .c = 0 };

    var playerX: i16 = SCREEN_WIDTH / 2;
    var playerY: i16 = SCREEN_HEIGHT / 2;

    while (!c.TCOD_console_is_window_closed()) {
        // Clear
        c.TCOD_console_clear(params.console);

        // Print
        c.TCOD_console_print(params.console, playerX, playerY, "@");

        // Render (ignore errors)
        _ = c.TCOD_context_present(context, params.console, null);

        // Events (ignore errors)
        _ = c.TCOD_sys_check_for_event(c.TCOD_EVENT_KEY_PRESS, &key, null);
        const optionalAction = evKeydown(key);
        if (optionalAction) |action| {
            switch (action) {
                ActionType.escapeAction => return,
                ActionType.moveAction => |m| {
                    playerX += m.dx;
                    playerY += m.dy;
                },
            }
        }
    }
}

// Structs for the available action types
const EscapeAction = struct {};
const MoveAction = struct { dx: i16, dy: i16 };

// This enum is used to create a tagged union of actions
const ActionTypeTag = enum {
    escapeAction,
    moveAction,
};

// Action type union; this structure can only have 1 active union value at a time
// and can be used in switch statements!
const ActionType = union(ActionTypeTag) {
    escapeAction: EscapeAction,
    moveAction: MoveAction,
};

// Returns a TCOD key struct initialized with an empty key code
fn initKey() c.TCOD_key_t {
    return c.TCOD_key_t{ .vk = c.TCODK_NONE, .c = 0, .text = undefined, .pressed = undefined, .lalt = undefined, .lctrl = undefined, .lmeta = undefined, .ralt = undefined, .rctrl = undefined, .rmeta = undefined, .shift = undefined };
}

fn initKeyWithVk(initialVk: c_uint) c.TCOD_key_t {
    var k = initKey();
    k.vk = initialVk;
    return k;
}

// This function takes a keydown event key and returns an optional action type to respond to the event
fn evKeydown(key: c.TCOD_key_t) ?ActionType {
    return switch (key.vk) {
        c.TCODK_ESCAPE => ActionType{ .escapeAction = EscapeAction{} },
        c.TCODK_UP => ActionType{ .moveAction = MoveAction{ .dx = 0, .dy = -1 } },
        c.TCODK_DOWN => ActionType{ .moveAction = MoveAction{ .dx = 0, .dy = 1 } },
        c.TCODK_LEFT => ActionType{ .moveAction = MoveAction{ .dx = -1, .dy = 0 } },
        c.TCODK_RIGHT => ActionType{ .moveAction = MoveAction{ .dx = 1, .dy = 0 } },
        else => null,
    };
}

test "evKeydown up" {
    const action = evKeydown(initKeyWithVk(c.TCODK_UP)).?;
    try expect(action.moveAction.dx == 0);
    try expect(action.moveAction.dy == -1);
}

test "initKeyWithVk should set given key on returned structure" {
    const key = initKeyWithVk(c.TCODK_UP);
    try expect(key.vk == c.TCODK_UP);
}
