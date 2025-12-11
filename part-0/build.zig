const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

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

    const run_cmd = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize
        }),
    });
    exe_tests.linkLibC();
    exe_tests.linkSystemLibrary("libtcod");

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
