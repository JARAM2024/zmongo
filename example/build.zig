const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zmongo-example",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // resolve to zmongo
    const zmongo = b.dependency("zmongo", .{});
    exe.root_module.addImport("zmongo", zmongo.module("zmongo"));

    exe.addLibraryPath(.{ .cwd_relative = zmongo.builder.pathFromRoot(zmongo.module("libpath").root_source_file.?.path) });
    exe.linkSystemLibrary("sasl2");
    exe.linkSystemLibrary("ssl");
    exe.linkSystemLibrary("crypto");
    exe.linkSystemLibrary("rt");
    exe.linkSystemLibrary("pthread");
    exe.linkSystemLibrary("z");
    exe.linkSystemLibrary("zstd");
    exe.linkSystemLibrary("icuuc");

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);

    // run_cmd.setEnvironmentVariable("LD_LIBRARY_PATH", zmongo.builder.pathFromRoot(zmongo.module("libpath").root_source_file.?.path));

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
