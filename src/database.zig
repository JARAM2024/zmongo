const c = @import("c.zig").lib;

pub const Database = struct {
    ptr: *c.mongoc_database_t,

    const Self = @This();
};
