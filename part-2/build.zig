const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Application exe
    const exe = b.addExecutable(.{ .name = "zrl", .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize }) });
    exe.linkLibC();
    b.installArtifact(exe);
    const options = b.addOptions();

    // Check if TARGET is macOS
    if (target.result.os.tag == .macos) {
        options.addOption(bool, "use_sdl3", true);
        exe.linkSystemLibrary("tcod");
        exe.linkSystemLibrary("SDL3");

        // specific to Apple Silicon (M1/M2/M3)
        exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });

        // Optional: Support Intel Macs too (they use /usr/local)
        exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
        exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    } else {
        options.addOption(bool, "use_sdl3", false);
        exe.linkSystemLibrary("libtcod");
        exe.linkSystemLibrary("SDL2");
    }
    exe.root_module.addOptions("config", options);

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

    // Check if TARGET is macOS
    if (target.result.os.tag == .macos) {
        exe_tests.linkSystemLibrary("tcod");

        // specific to Apple Silicon (M1/M2/M3)
        exe_tests.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        exe_tests.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });

        // Optional: Support Intel Macs too (they use /usr/local)
        exe_tests.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
        exe_tests.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    } else {
        exe_tests.linkSystemLibrary("libtcod");
    }

    // Set up the `zig build test` command
    const run_tests = b.addRunArtifact(exe_tests);
    const run_tests_step = b.step("test", "Run unit tests");
    run_tests_step.dependOn(&run_tests.step);
}
