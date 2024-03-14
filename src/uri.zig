const std = @import("std");
const c = @import("c.zig").lib;
const bson = @import("bson.zig");
const mongo = @import("mongo.zig");

const Error = mongo.Error;

pub const Uri = struct {
    ptr: ?*c.mongoc_uri_t,

    const Self = @This();

    pub fn new(uri_string: [:0]const u8) !Self {
        var err: c.bson_error_t = undefined;
        const ptr = c.mongoc_uri_new_with_error(uri_string, &err);
        if (ptr != null) {
            return Self{
                .ptr = ptr,
            };
        } else {
            std.debug.print("Uri.new() parsing URI string {s} failed: {s}\n", .{ uri_string, std.mem.sliceTo(&err.message, 0) });
            return Error.UriError;
        }
    }
};
