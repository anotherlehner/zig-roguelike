//! zig-roguelike, by @trymartinlehner

// using small values now because the resulting window is large and easy to see
pub const SCREEN_WIDTH: i32 = 80;
pub const SCREEN_HEIGHT: i32 = 50;

// ascii code for the @ character
pub const ASCII_AT: u8 = 64;

// map constants
pub const ROOM_MAX_SIZE = 10;
pub const ROOM_MIN_SIZE = 6;
pub const ROOM_MAX_MONSTERS = 2;
pub const MAX_ROOMS = 30;
