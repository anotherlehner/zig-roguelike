//! zig-roguelike, by Martin Lehner (@anotherlehner)

pub const TITLE = "Zig Roguelike";
pub const TILESET = "../dejavu10x10_gs_tc.png";

// using small values now because the resulting window is large and easy to see
pub const SCREEN_WIDTH: i32 = 80;
pub const SCREEN_HEIGHT: i32 = 50;

// map constants
pub const ROOM_MAX_SIZE = 10;
pub const ROOM_MIN_SIZE = 6;
pub const ROOM_MAX_MONSTERS = 2;
pub const MAX_ROOMS = 30;
