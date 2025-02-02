const std = @import("std");

fn lazyPathFromRoot(b: *std.Build, sub_path: []const u8) std.Build.LazyPath {
    return .{ .src_path = .{
        .owner = b,
        .sub_path = sub_path,
    } };
}

pub fn build(b: *std.Build) void {
    const zmongo = b.addModule("zmongo", .{
        .root_source_file = b.path("src/root.zig"),
    });

    const libmongoc = b.dependency("libmongoc", .{});

    const libpath = b.addModule("libpath", .{
        .root_source_file = lazyPathFromRoot(libmongoc.builder, libmongoc.module("libmongoc.library").root_source_file.?.src_path.sub_path),
    });

    const mod = b.addModule("zmongo_module", .{
        .root_source_file = b.path("zmongo.zig"),
        .imports = &.{ .{
            .name = "zmongo",
            .module = zmongo,
        }, .{
            .name = "libpath",
            .module = libpath,
        } },
    });

    zmongo.addIncludePath(b.path("./libmongoc/include/"));
    zmongo.link_libc = true;

    _ = mod;

    // bson unit tests
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const bson_tests = b.addTest(.{
        .root_source_file = b.path("src/bson_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    bson_tests.step.dependOn(b.getInstallStep());
    bson_tests.linkLibC();
    bson_tests.addLibraryPath(.{ .cwd_relative = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.src_path.sub_path) });
    bson_tests.addIncludePath(.{ .cwd_relative = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.include").root_source_file.?.src_path.sub_path) });
    bson_tests.linkSystemLibrary("bson-static-1.0");

    //-lsasl2 -lssl -lcrypto -lrt -lresolv -pthread -lz -lzstd -licuuc
    bson_tests.linkSystemLibrary("sasl2-static");
    bson_tests.linkSystemLibrary("ssl-static");
    bson_tests.linkSystemLibrary("crypto-static");
    // bson_tests.linkSystemLibrary("rt-static");
    bson_tests.linkSystemLibrary("resolv-static");
    // bson_tests.linkSystemLibrary("pthread-static");
    bson_tests.linkSystemLibrary("z-static");
    bson_tests.linkSystemLibrary("zstd-static");
    bson_tests.linkSystemLibrary("icuuc-static");

    const run_bson_tests = b.addRunArtifact(bson_tests);
    run_bson_tests.setEnvironmentVariable("LD_LIBRARY_PATH", libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.src_path.sub_path));
    run_bson_tests.has_side_effects = true; // no cache

    const test_bson_step = b.step("test-bson", "run bson unit tests");
    test_bson_step.dependOn(&run_bson_tests.step);

    // mongo unit test
    const mongo_tests = b.addTest(.{
        .root_source_file = b.path("src/mongo_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    mongo_tests.step.dependOn(b.getInstallStep());
    mongo_tests.linkLibC();
    mongo_tests.addLibraryPath(.{ .cwd_relative = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.src_path.sub_path) });
    mongo_tests.addIncludePath(.{ .cwd_relative = libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.include").root_source_file.?.src_path.sub_path) });
    mongo_tests.linkSystemLibrary("bson-static-1.0");
    mongo_tests.linkSystemLibrary("mongoc-static-1.0");

    //-lsasl2 -lssl -lcrypto -lrt -lresolv -pthread -lz -lzstd -licuuc
    mongo_tests.linkSystemLibrary("sasl2-static");
    mongo_tests.linkSystemLibrary("ssl-static");
    mongo_tests.linkSystemLibrary("crypto-static");
    // mongo_tests.linkSystemLibrary("rt-static");
    mongo_tests.linkSystemLibrary("resolv-static");
    // mongo_tests.linkSystemLibrary("pthread-static");
    mongo_tests.linkSystemLibrary("z-static");
    mongo_tests.linkSystemLibrary("zstd-static");
    mongo_tests.linkSystemLibrary("icuuc-static");

    const run_mongo_tests = b.addRunArtifact(mongo_tests);
    run_mongo_tests.setEnvironmentVariable("LD_LIBRARY_PATH", libmongoc.builder.pathFromRoot(libmongoc.module("libmongoc.library").root_source_file.?.src_path.sub_path));
    run_mongo_tests.has_side_effects = true; // no cache

    const test_mongo_step = b.step("test-mongo", "run mongo unit tests");
    test_mongo_step.dependOn(&run_mongo_tests.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    run_lib_unit_tests.has_side_effects = true; // disable cache

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(test_bson_step);
    test_step.dependOn(test_mongo_step);
}
