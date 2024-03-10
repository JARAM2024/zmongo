const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // export `zmongo` module
    _ = b.addModule("zmongo", .{ .root_source_file = .{ .path = "src/root.zig" } });

    const libmongoc = b.dependency("libmongoc", .{});

    const lib = b.addStaticLibrary(.{
        .name = "zmongo",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("libmongoc.library", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.path) } });
    _ = b.addModule("libmongoc.include", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.include").root_source_file.?.path) } });
    _ = b.addModule("libmongoc.bson", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.bson").root_source_file.?.path) } });
    _ = b.addModule("libmongoc.mongoc", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.mongoc").root_source_file.?.path) } });
    _ = b.addModule("libmongoc.h", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.h").root_source_file.?.path) } });
    _ = b.addModule("libbson.h", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libbson.h").root_source_file.?.path) } });
    _ = b.addModule("libmongoc.so", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.so").root_source_file.?.path) } });
    _ = b.addModule("libbson.so", .{ .root_source_file = .{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libbson.so").root_source_file.?.path) } });

    b.installArtifact(lib);

    // bson unit tests
    const bson_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/bson_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    bson_tests.step.dependOn(b.getInstallStep());
    bson_tests.linkLibC();
    bson_tests.addLibraryPath(.{ .cwd_relative = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.path) });
    bson_tests.addIncludePath(.{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.include").root_source_file.?.path) });
    bson_tests.linkSystemLibrary("libbson-1.0");

    const run_bson_tests = b.addRunArtifact(bson_tests);
    run_bson_tests.setEnvironmentVariable("LD_LIBRARY_PATH", libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.path));

    const test_bson_step = b.step("test-bson", "run bson unit tests");
    test_bson_step.dependOn(&run_bson_tests.step);

    // mongo unit test
    const mongo_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mongo_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    mongo_tests.step.dependOn(b.getInstallStep());
    mongo_tests.linkLibC();
    mongo_tests.addLibraryPath(.{ .cwd_relative = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.path) });
    mongo_tests.addIncludePath(.{ .path = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.include").root_source_file.?.path) });
    mongo_tests.linkSystemLibrary("libmongoc-1.0");

    const run_mongo_tests = b.addRunArtifact(mongo_tests);
    run_mongo_tests.setEnvironmentVariable("LD_LIBRARY_PATH", libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.path));

    const test_mongo_step = b.step("test-mongo", "run mongo unit tests");
    test_mongo_step.dependOn(&run_mongo_tests.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(test_bson_step);
    test_step.dependOn(test_mongo_step);
}
