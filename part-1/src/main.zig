//! zig-roguelike, by @trymartinlehner
const std = @import("std");
const expect = std.testing.expect;

// translate and import the libtcod C library headers
const c = @cImport({
    @cInclude("libtcod.h");
});

// using small values now because the resulting window is large and easy to see
const SCREEN_WIDTH = 40;
const SCREEN_HEIGHT = 25;

// ascii code for the @ character
const ASCII_AT = 64;

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

pub fn main() anyerror!void {
    _ = c.TCOD_console_init_root(SCREEN_WIDTH, SCREEN_HEIGHT, "Zig Roguelike", false, c.TCOD_RENDERER_SDL2);
    defer { // Make sure the quit function is called when main() exits
        c.TCOD_quit();
    }

    var key = c.TCOD_key_t{ .vk = c.TCODK_NONE, .c = 0, .text = undefined, .pressed = undefined, .lalt = undefined, .lctrl = undefined, .lmeta = undefined, .ralt = undefined, .rctrl = undefined, .rmeta = undefined, .shift = undefined };
    var playerX: i16 = SCREEN_WIDTH / 2; // initial player x position
    var playerY: i16 = SCREEN_HEIGHT / 2; // initial player y position
    // std.log.info("player x: {d}, y: {d}", .{ playerX, playerY });

    _ = c.TCOD_console_set_custom_font("../dejavu10x10_gs_tc.png", c.TCOD_FONT_TYPE_GREYSCALE | c.TCOD_FONT_LAYOUT_TCOD, 0, 0);

    while (!c.TCOD_console_is_window_closed()) {
        // Clear
        c.TCOD_console_clear(null);

        // Render
        c.TCOD_console_set_char(null, playerX, playerY, ASCII_AT); // draw the player symbol
        _ = c.TCOD_console_flush(); // render the drawn console to the screen

        // Events
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
