const std = @import("std");

fn lazyPathFromRoot(b: *std.Build, sub_path: []const u8) std.Build.LazyPath {
    return .{ .src_path = .{
        .owner = b,
        .sub_path = sub_path,
    } };
}

pub fn build(b: *std.Build) !void {
    _ = b.addModule("libmongoc.include", .{ .root_source_file = lazyPathFromRoot(b, "include") });
    _ = b.addModule("libmongoc.library", .{ .root_source_file = lazyPathFromRoot(b, "lib") });
    _ = b.addModule("libmongoc.bson", .{ .root_source_file = lazyPathFromRoot(b, "include/bson") });
    _ = b.addModule("libmongoc.mongoc", .{ .root_source_file = lazyPathFromRoot(b, "include/mongoc") });
    _ = b.addModule("libmongoc.mongoc.h", .{ .root_source_file = lazyPathFromRoot(b, "include/mongo.h") });
}
