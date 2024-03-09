const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = b.addModule("mongoz", .{ .root_source_file = .{ .path = "root.zig" } });

    const lib = b.addStaticLibrary(.{
        .name = "mongoz",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.linkSystemLibrary("libmongoc-1.0");
    lib.linkLibC();

    b.installArtifact(lib);

    // bson unit tests
    const bson_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/bson_test.zig" },
        .target = target,
        .optimize = optimize,
    });
    bson_tests.linkLibC();
    bson_tests.linkSystemLibrary("libmongoc-1.0");
    const run_bson_tests = b.addRunArtifact(bson_tests);
    const test_bson_step = b.step("test-bson", "run bson unit tests");
    test_bson_step.dependOn(&run_bson_tests.step);

    // mongo unit test
    const mongo_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mongo_test.zig" },
        .target = target,
        .optimize = optimize,
    });
    mongo_tests.linkLibC();
    mongo_tests.linkSystemLibrary("libmongoc-1.0");
    const run_mongo_tests = b.addRunArtifact(mongo_tests);
    const test_mongo_step = b.step("test-mongo", "run mongo unit tests");
    test_mongo_step.dependOn(&run_mongo_tests.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.linkLibC();
    lib_unit_tests.linkSystemLibrary("libmongoc-1.0");
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(test_bson_step);
    test_step.dependOn(test_mongo_step);
}
