const std = @import("std");

pub fn build(b: *std.Build) !void {
    _ = b.addModule("libmongoc.library", .{ .root_source_file = .{ .path = b.pathFromRoot("lib") } });
    _ = b.addModule("libmongoc.include", .{ .root_source_file = .{ .path = b.pathFromRoot("include") } });
    _ = b.addModule("libmongoc.h", .{ .root_source_file = .{ .path = b.pathFromRoot("include/mongoc.h") } });
    _ = b.addModule("libbson.h", .{ .root_source_file = .{ .path = b.pathFromRoot("include/bson.h") } });
    _ = b.addModule("libmongoc.so", .{ .root_source_file = .{ .path = b.pathFromRoot("lib/libmongoc-1.0.so") } });
    _ = b.addModule("libbson.so", .{ .root_source_file = .{ .path = b.pathFromRoot("lib/libbson-1.0.so") } });
}
