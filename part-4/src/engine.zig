//! zig-roguelike, by @anotherlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const models = @import("models.zig");
const constants = @import("constants.zig");
const actions = @import("actions.zig");
const expect = std.testing.expect;

pub const Engine = struct {
    entities: []*models.Entity,
    player: *models.Entity,
    console: tcod.TcodConsole,
    map: *models.Map,
    isQuit: bool = false,

    pub fn handleEvents(self: *Engine) void {
        var key = initKey();
        tcod.sysCheckForEvent(&key);
        const optionalAction = evKeydown(key);
        if (optionalAction) |action| {
            actions.perform(action, self);
        }
        tcod.computeFov(self.map.tcMap, self.player.x, self.player.y);
    }

    pub fn render(self: *Engine) void {
        tcod.consoleClear(self.console);
        tcod.renderMap(self.console, self.map);
        for (self.entities) |ent| {
            tcod.consolePutCharEx(self.console, ent.x, ent.y, ent.glyph, ent.color, .{.r=0,.g=0,.b=0});
        }
        tcod.consoleBlit(self.console, constants.SCREEN_WIDTH,constants.SCREEN_HEIGHT);
        tcod.consoleFlush();
    }

    pub fn init(entities: []*models.Entity, player: *models.Entity, console: tcod.TcodConsole, map: *models.Map) Engine {
        return Engine{
            .entities=entities,
            .player=player,
            .console=console,
            .map=map,
        };
    }
    
    pub fn quit(self: *Engine) void {
        self.isQuit = true;
    }
};

fn initKeyWithVk(initialVk: c_uint) tcod.TcodKey {
    var k = initKey();
    k.vk = initialVk;
    return k;
}

// Returns a TCOD key struct initialized with an empty key code
fn initKey() tcod.TcodKey {
    return tcod.TcodKey{ .vk = tcod.KeyNone, .c = 0, .text = undefined, .pressed = undefined, .lalt = undefined, .lctrl = undefined, .lmeta = undefined, .ralt = undefined, .rctrl = undefined, .rmeta = undefined, .shift = undefined };
}

// This function takes a keydown event key and returns an optional action type to respond to the event
fn evKeydown(key: tcod.TcodKey) ?models.ActionType {
    return switch (key.vk) {
        tcod.KeyEscape => models.ActionType{ .escapeAction = models.EscapeAction{} },
        tcod.KeyUp => models.ActionType{ .moveAction = models.MoveAction{ .dx = 0, .dy = -1 } },
        tcod.KeyDown => models.ActionType{ .moveAction = models.MoveAction{ .dx = 0, .dy = 1 } },
        tcod.KeyLeft => models.ActionType{ .moveAction = models.MoveAction{ .dx = -1, .dy = 0 } },
        tcod.KeyRight => models.ActionType{ .moveAction = models.MoveAction{ .dx = 1, .dy = 0 } },
        else => null,
    };
}

test "evKeydown up" {
    const action = evKeydown(initKeyWithVk(tcod.KeyUp)).?;
    try expect(action.moveAction.dx == 0);
    try expect(action.moveAction.dy == -1);
}

test "initKeyWithVk should set given key on returned structure" {
    const key = initKeyWithVk(tcod.KeyUp);
    try expect(key.vk == tcod.KeyUp);
}
