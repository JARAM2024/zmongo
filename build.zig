const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = b.addModule("zmongo", .{ .root_source_file = .{ .path = "src/root.zig" } });

    const lib = b.addStaticLibrary(.{
        .name = "zmongo",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.installHeader("c/include/bson.h", "bson.h");
    lib.installHeader("c/include/mongoc.h", "mongoc.h");
    lib.installHeadersDirectory("c/include/bson", "bson");
    lib.installHeadersDirectory("c/include/mongoc", "mongoc");

    lib.addIncludePath(.{ .path = "c/include/" });
    lib.addIncludePath(.{ .path = "c/include/bson" });
    lib.addIncludePath(.{ .path = "c/include/mongoc" });

    lib.addLibraryPath(.{ .cwd_relative = "c/lib/" });
    lib.linkSystemLibrary("libbson-1.0");
    lib.linkSystemLibrary("libmongoc-1.0");

    lib.linkLibC();

    b.installArtifact(lib);

    // bson unit tests
    const bson_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/bson_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    bson_tests.addIncludePath(.{ .path = "c/include/" });
    bson_tests.addIncludePath(.{ .path = "c/include/bson" });
    bson_tests.addIncludePath(.{ .path = "c/include/mongoc" });

    bson_tests.addLibraryPath(.{ .cwd_relative = "c/lib/" });
    bson_tests.linkSystemLibrary("libbson-1.0");
    bson_tests.linkSystemLibrary("libmongoc-1.0");

    bson_tests.linkLibC();

    const run_bson_tests = b.addRunArtifact(bson_tests);

    const test_bson_step = b.step("test-bson", "run bson unit tests");
    test_bson_step.dependOn(&run_bson_tests.step);

    // mongo unit test
    const mongo_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/mongo_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    mongo_tests.addIncludePath(.{ .path = "c/include/" });
    mongo_tests.addIncludePath(.{ .path = "c/include/bson" });
    mongo_tests.addIncludePath(.{ .path = "c/include/mongoc" });

    // mongo_tests.addObjectFile(.{ .path = "c/lib/libbson-static-1.0.a" });
    // mongo_tests.addObjectFile(.{ .path = "c/lib/libmongoc-static-1.0.a" });

    mongo_tests.addLibraryPath(.{ .cwd_relative = "c/lib/" });
    mongo_tests.linkSystemLibrary("libbson-1.0");
    mongo_tests.linkSystemLibrary("libmongoc-1.0");

    mongo_tests.linkLibC();
    const run_mongo_tests = b.addRunArtifact(mongo_tests);

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
