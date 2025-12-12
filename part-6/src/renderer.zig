//! zig-roguelike, by @anotherlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const map = @import("map.zig");
const color = @import("color.zig");
const ent = @import("entity.zig");

pub fn render(console: tcod.TcodConsole, m: *map.Map, player: *ent.Entity) void {
    tcod.consoleClear(console);
    renderMap(console, m);

    const msg = std.fmt.allocPrint(m.allocator, "hp: {d}/{d}", .{ player.component.fighter.hp, player.component.fighter.maxHp }) catch @panic("eom");
    tcod.consolePrint(console, 1, 47, msg);
    m.allocator.free(msg);

    tcod.consoleBlit(console, m.width, m.height);
    tcod.consoleFlush();
}

fn renderMap(console: tcod.TcodConsole, m: *map.Map) void {
    var x: i32 = 0;
    var y: i32 = 0;
    for (m.cells, 0..) |t, index| {
        if (tcod.mapIsInFov(m.tcMap, x, y)) {
            m.cells[index].visible = true;
            m.cells[index].explored = true;
        } else {
            m.cells[index].visible = false;
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
            console.tiles[index].ch = color.SHROUD.ch;
            console.tiles[index].fg = color.SHROUD.fg;
            console.tiles[index].bg = color.SHROUD.bg;
        }

        x += 1;
        if (@mod(x, m.width) == 0) {
            y += 1;
            x = 0;
        }
    }

    const orderedEntities = m.getRenderOrderedEntities();

    for (orderedEntities) |e| {
        const tile = m.get(e.x, e.y);
        if (tile.visible) {
            const bg = tcod.TcodColorRGB{ .r = tile.light.bg.r, .g = tile.light.bg.g, .b = tile.light.bg.b };
            tcod.consolePutCharEx(console, e.x, e.y, e.glyph, e.color, bg);
        }
    }

    m.allocator.free(orderedEntities);
}
