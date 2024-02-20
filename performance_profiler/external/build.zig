const std = @import("std");

pub fn build(b: *std.Build) void {
    const lib = b.addStaticLibrary("ZigMicroUI", "src/main.zig");
    lib.linkSystemLibrary("c");
    lib.linkLibC();

    lib.setBuildMode(b.standardTargetOptions(.{}));
    lib.install();

    const exe = b.addExecutable(.{
        .name = "PPler",
        .root_source_file = .{
            .path = "profiler/main.zig",
        },
        .target = b.host,
    });
    b.installArtifact(exe);
}
