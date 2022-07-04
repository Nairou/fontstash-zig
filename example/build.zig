const std = @import("std");
const freetype = @import("build-freetype.zig");
const glfw = @import("deps/mach-glfw/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("example", "example.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    if (target.toTarget().os.tag == .windows) {
        exe.subsystem = std.Target.SubSystem.Windows;
    }

    exe.addIncludeDir("../");
    exe.addIncludeDir("deps/");
    exe.addIncludeDir("deps/glad/");
    exe.addIncludeDir("deps/zgl/");
    exe.addIncludeDir("deps/freetype/include/");

    exe.addCSourceFile("../upstream/fontstash.c", &[_][]const u8{ "-std=c99" });
    exe.addCSourceFile("deps/glad/gl.c", &[_][]const u8{ "-std=c11" });

    exe.addPackagePath("fontstash", "../fontstash.zig");
    exe.addPackagePath("glfontstash", "../glfontstash.zig");

    exe.linkLibC();
    const libFreeType = freetype.buildLibrary(b, mode, target);
    exe.linkLibrary(libFreeType);
    exe.addPackage(glfw.pkg);
    glfw.link(b, exe, .{});

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
