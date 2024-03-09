const c = @import("c.zig").lib;

pub fn init() void {
    return c.mongoc_init();
}

pub fn cleanup() void {
    c.mongoc_cleanup();
    return;
}

pub const Error = error{
    MongoError,
    UriError,
    ClientError,
    DatabaseError,
    CollectionError,
};

pub const Uri = @import("uri.zig").Uri;
pub const Client = @import("client.zig").Client;
pub const Database = @import("database.zig").Database;
pub const Collection = @import("collection.zig").Colection;
