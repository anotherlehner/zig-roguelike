# Part 0: Setting Up

## Install Zig

Download Zig from the ziglang homepage: https://ziglang.org/download/

I downloaded and installed the latest master version (zig-0.10.0-dev) and stuck that into a local folder, which I then added to my path.

## Create the project

Zig makes it easy to initialize a simple project:

```
mkdir part-0
cd part-0/
zig init-exe
```

This generates a `build.zig` file and `src` folder containing a single `main.zig`. The `build.zig` file is part of Zig's build system and provides a code-based configuration of how the project should be compiled, built, tested, installed, etc. I will describe basic usage of this below and get into details in later parts of how to configure this.

## System-based configuration

Since I wanted to make this as easy on myself as possible I decided to see if I could use libtcod from zig installed as a system dev package. I'm on PopOS so I did a quick apt search and found that indeed a slightly older version of libtcod is available!

```
libtcod-dev - development files for the libtcod roguelike library
libtcod1 - graphics and utility library for roguelike developers
```

For me this installed libtcod (and headers) for version 1.18.1. About a year old, not too bad. I will go with that for now.

I'm going to be using the libtcod C API and use some previous years roguelike tutorial attempts in C and the `samples_c.c` that comes with the libtcod source for guidance, among other things. I'll try to note links in each part to websites I used to gain information.

## Vcpkg configuration

TODO

Attempt to compile and link against libtcod installed with the vcpkg tool described in the libtcod documentation.

## From-source configuration

TODO

Attempt to compile and link against libtcod installed directly from source built locally.

## Configuring Zig to build using libtcod

To get Zig to compile and link with libtcod we need to make a couple of changes to the `build.zig` file. Between `exe.setBuildMode` and `exe.install` I added a couple lines to tell I want to link with libc and libtcod:

```zig
exe.linkLibC();
exe.linkSystemLibrary("libtcod");
```

The other thing we need to do is import the C header in the `main.zig` source file itself. This tells Zig to import that header and make the C code available for us to call:

```zig
const c = @cImport({
    @cInclude("libtcod.h");
});
```

To make sure things were working right I also grabbed a constant from inside the libtcod C header and tried printing it out in the Zig log statement:

```zig
std.log.info("tcod red: {s}", .{c.TCOD_red});
```

`{s}` means print the value as a string.

## Building and running

To build and run the project Zig provides several commands but for now let's stay basic and just use `zig build run`.

We get the following output:

```
info: tcod red: .cimport:3:11.struct_TCOD_ColorRGB{ .r = 255, .g = 0, .b = 0 }
```

Hello libtcod world?

## Tests

I like tests. Zig gives us tests embedded in the code, which we can easily run with `zig test`. Since I'm using C imports and libraries I need to add those on the command line:

```
zig test src/main.zig --library tcod --library c
```

At the moment I just have 1 test that checks to see if the `TCOD_red.r` constant has a value of `255` (basically checking to see that we can import the C header and access the value inside without any errors...

```
All 1 tests passed.
```

This feels more like an "integration test" than a unit test at the moment. Also, I'm not so sure about `--library` since Windows doesn't have system libraries like linux does. Reading the following Zig issue thread makes me think I should port this to the `build.zig` file and use `--library-path` instead.

https://github.com/ziglang/zig/issues/2041

After reading this I realized I had already used the new function discussed to configure libtcod for the regular exe build. I went back to my `build.zig` file and added essentially same two lines (`linkLibC()` and `linkSystemLibrary("libtcod")`) to the `exe_tests` part.

Reran the tests this time using `zig build test`, which doesn't require me to specify a certain zig file to test...

```
All 1 tests passed.
```

Hooray! I like the latter approach here of using the `build.zig` configuration with `zig build test`.

## Notes

Just opened this up today after working on it last night and ran `zig build run` but got an error that `cimport.zig` couldn't be found?
- deleted the `zig-cache` and `zig-out` folder and ran again and things worked as expected

## Links

Zig official docs build chapter
https://ziglearn.org/chapter-3/

Using Zig build system series (part 1)
https://zig.news/xq/zig-build-explained-part-1-59lf
