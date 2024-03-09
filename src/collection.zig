const c = @import("c.zig").lib;

pub const Collection = struct {
    ptr: *c.mongoc_collection_t,
};
