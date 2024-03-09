const std = @import("std");
const c = @import("c.zig").lib;
const bson = @import("bson.zig");
const mongo = @import("mongo.zig");

const Error = mongo.Error;

pub const Uri = struct {
    ptr: ?*c.mongoc_uri_t,

    const Self = @This();

    pub fn new(uri_string: [:0]const u8) !Self {
        const err = bson.BsonError.init();
        const ptr = c.mongoc_uri_new_with_error(uri_string, err.ptr());
        if (ptr != null) {
            return Self{
                .ptr = ptr,
            };
        } else {
            // error populated in err
            std.debug.print("URI_ERROR: Parsing URI string {s} failed: {s}\n", .{ uri_string, err.message() });
            return Error.UriError;
        }
    }
};
