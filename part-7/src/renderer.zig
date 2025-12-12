//! zig-roguelike, by @anotherlehner

const std = @import("std");
const tcod = @import("tcod.zig");
const map = @import("map.zig");
const color = @import("color.zig");
const ent = @import("entity.zig");
const messagelog = @import("messagelog.zig");
const Allocator = std.mem.Allocator;
const MessageLog = messagelog.MessageLog;

pub fn render(console: tcod.TcodConsole, m: *map.Map, player: *ent.Entity, log: *MessageLog,
        mx: i32, my: i32) void {
    tcod.consoleClear(console);
    renderMap(console, m);
    renderBar(console, player.component.fighter.hp, player.component.fighter.maxHp, 20, m.allocator);
    renderMessages(console, 21, 45, 40, 4, log);
    renderExamine(console, m, mx, my);
    tcod.consoleBlit(console, m.width, m.height);
    tcod.consoleFlush();
}

fn renderExamine(console: tcod.TcodConsole, m: *map.Map, mx: i32, my: i32) void {
    if (!m.isInFov(mx,my)) return;
    var exText = m.examine(mx,my);
    tcod.consolePrintFgMaxLength(console, 0, 46, exText, color.White_rgb, 20);
    m.allocator.free(exText);
}

fn renderMessages(console: tcod.TcodConsole, x: i32, y: i32, width: i32, height: i32, log: *messagelog.MessageLog) void {
    var y_offset: i32 = y;
    var yi = @intCast(i64, log.messages.items.len)-1;
    var nRendered: i32 = 0;
    while (yi >= 0 and nRendered < height) : (yi -= 1) {
        var msg = &log.messages.items[@intCast(usize, yi)];
        if (msg.count > 1) {
            var fullMsg = std.fmt.allocPrint(log.allocator, "{} (x{d})",
                .{msg.text, msg.count}) catch @panic("eom");
            tcod.consolePrintFgMaxLength(console, x, y_offset, fullMsg, msg.fg, width);
            log.allocator.free(fullMsg);
        } else {
            tcod.consolePrintFgMaxLength(console, x, y_offset, msg.text, msg.fg, width);
        }
        
        nRendered += 1;
        y_offset += 1;
    }
}

fn renderBar(console: tcod.TcodConsole, curValue: i32, maxValue: i32, totWidth: i32, allocator: Allocator) void {
    var barWidth = @floatToInt(i32, @intToFloat(f32, curValue) / @intToFloat(f32, maxValue) * @intToFloat(f32, totWidth)); // cast?

    tcod.consoleDrawRectRgb(console, 0, 45, totWidth, 1, 1, color.Bar_empty, color.Bar_empty);

    if (barWidth > 0) {
        tcod.consoleDrawRectRgb(console, 0, 45, barWidth, 1, 1, color.Bar_filled, color.Bar_filled);
    }

    var msg = std.fmt.allocPrint(allocator, "hp: {d}/{d}", 
        .{curValue, maxValue}) catch @panic("eom");
    tcod.consolePrintFg(console, 1, 45, msg, color.White_rgb);
    allocator.free(msg);
}

fn renderMap(console: tcod.TcodConsole, m: *map.Map) void {
    var x: i32 = 0;
    var y: i32 = 0;
    for (m.cells) |t, index| {
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

        // TODO: Something is wrong here. If the map size is smaller than the screen size
        // then a black bar appears where the map isn't written but then console tiles
        // don't seem to be writable to those cells using the other tcod functions?
        // Why would not writing default black tiles here break the other functions?

        x += 1;
        if (@mod(x,m.width) == 0) {
            y += 1;
            x = 0;
        }
    }

    var orderedEntities = m.getRenderOrderedEntities();

    for (orderedEntities) |e| {
        var tile = m.get(e.x,e.y);
        if (tile.visible) {
            var bg = .{.r=tile.light.bg.r,.g=tile.light.bg.g,.b=tile.light.bg.b};
            tcod.consolePutCharEx(console, e.x, e.y, e.glyph, e.color, bg);
        }
    }

    m.allocator.free(orderedEntities);
}