const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Application exe
    const exe = b.addExecutable(.{ 
        .name = "part-0", 
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize
        })
    });
    exe.linkLibC();
    exe.linkSystemLibrary("libtcod");
    b.installArtifact(exe);

    // Set up the `zig build run` command to execute the app
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const exe_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
        }),
    });
    exe_tests.linkLibC();
    exe_tests.linkSystemLibrary("libtcod");

    // Set up the `zig build test` command
    const run_tests = b.addRunArtifact(exe_tests);
    const run_tests_step = b.step("test", "Run unit tests");
    run_tests_step.dependOn(&run_tests.step);
}
