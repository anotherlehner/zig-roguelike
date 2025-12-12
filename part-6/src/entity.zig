//! zig-roguelike, by @anotherlehner
const std = @import("std");
const tcod = @import("tcod.zig");
const color = @import("color.zig");
const ai = @import("ai.zig");
const Allocator = std.mem.Allocator;

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

pub const Entity = struct {
    x: i32 = 0,
    y: i32 = 0,
    glyph: u8 = '?',
    color: tcod.TcodColorRGB = color.rgb(255,255,255),
    name: []const u8 = "Unnamed",
    blocksMovement: bool = false,
    // components: []ComponentType = undefined, TODO
    component: ComponentType = null,
    ai: ?ai.AIType = null, // optional ai
    isPlayer: bool = false,
    renderOrder: RenderOrder = RenderOrder.corpse,

    pub fn move(self: *Entity, dx: i32, dy: i32) void {
        self.x += dx;
        self.y += dy;
    }
};

pub fn renderOrderComparator(context: void, a: *Entity, b: *Entity) bool {
    _ = context;
    return @enumToInt(a.renderOrder) < @enumToInt(b.renderOrder);
}

pub const ComponentFighter = struct {
    maxHp: i32,
    hp: i32,
    defense: i32,
    power: i32,

    pub fn setHp(self: *ComponentFighter, value: i32) void {
        self.hp = @maximum(0, @minimum(value, self.maxHp));
    }

    pub fn isAlive(self: *ComponentFighter) bool {
        return self.hp > 0;
    }
};

pub fn die(e: *Entity) void {
    if (e.isPlayer) {
        std.debug.print("You died!\n", .{});
    } else {
        std.debug.print("{} died!\n", .{e.name});
    }

    e.glyph = '%';
    e.color = color.rgb(191, 0, 0);
    e.blocksMovement = false;
    e.ai = null;
    e.name = "{}'s remains";
    e.renderOrder = RenderOrder.corpse;
}

pub fn orc(x: i32, y: i32, allocator: Allocator) !*Entity {
    const e = try allocator.create(Entity);
    e.x = x;
    e.y = y;
    e.glyph='o';
    e.color = color.rgb(63,127,63);
    e.name="Orc";
    e.blocksMovement = true;
    e.component.fighter = ComponentFighter{.maxHp=10, .hp=10, .defense=0, .power=3};
    e.ai = ai.AIType.hostile;
    e.renderOrder = RenderOrder.actor;
    return e;
}

pub fn troll(x: i32, y: i32, allocator: Allocator) !*Entity {
    const e = try allocator.create(Entity);
    e.x = x;
    e.y = y;
    e.glyph = 'T';
    e.color = color.rgb(0,127,0);
    e.name="Troll";
    e.blocksMovement = true;
    e.component.fighter = ComponentFighter{.maxHp=16, .hp=16, .defense=1, .power=4};
    e.renderOrder = RenderOrder.actor;
    return e;
}

pub fn player(x: i32, y: i32, allocator: Allocator) !*Entity {
    const e = try allocator.create(Entity);
    e.x = x;
    e.y = y;
    e.glyph = '@';
    e.color = color.rgb(255,255,255);
    e.name = "Player";
    e.blocksMovement = true;
    e.component.fighter = ComponentFighter{.maxHp=30, .hp=30, .defense=2, .power=5};
    e.isPlayer = true;
    e.renderOrder = RenderOrder.actor;
    return e;
}