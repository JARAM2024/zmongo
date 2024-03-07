const c = @cImport({
    @cInclude("mongoc.h");
    @cInclude("bson.h");
});

const std = @import("std");

const Error = error{
    MongoError,
    UriError,
    ClientError,
    DatabaseError,
    CollectionError,
};

const BsonError = c.bson_error_t;

pub fn init(log_level: c_uint, log_domain: [:0]const u8, message: [:0]const u8) void {
    // initialize log handler to capture client exception.
    c.mongoc_log_default_handler(log_level, log_domain, message, null);
    c.mongoc_log_set_handler(c.mongoc_log_default_handler, null);

    c.mongoc_init();
}

pub fn cleanup() void {
    c.mongoc_cleanup();
}

pub const Uri = struct {
    ptr: *c.mongoc_uri_t,

    const Self = @This();

    pub fn new(uri_string: [:0]const u8, err: *BsonError) !Self {
        if (c.mongoc_uri_new_with_error(uri_string, err)) |ptr| {
            return Self{
                .ptr = ptr,
            };
        } else {
            return Error.UriError;
        }
    }
};

pub const Client = struct {
    ptr: *c.mongoc_client_t,

    const Self = @This();

    pub fn new(uri: Uri, err: *BsonError) !Self {
        if (c.mongoc_client_new_from_uri_with_error(uri.ptr, err)) |cli| {
            return Self{
                .ptr = cli,
            };
        } else {
            return Error.ClientError;
        }
    }
};

pub const Database = struct {
    ptr: c.mongoc_database_t,

    const Self = @This();
};

pub const Collection = struct {
    ptr: c.mongoc_collection_t,
};

test "client init" {
    init(c.MONGOC_LOG_LEVEL_INFO, "zmongo", "ZMONGO DEBUG:");
    cleanup();
}

test "client_new" {
    init(c.MONGOC_LOG_LEVEL_INFO, "zmongo", "ZMONGO DEBUG:");
    cleanup();

    var err: BsonError = undefined;

    const uri = try Uri.new("mongodb://127.0.0.2", &err);
    if (err) {
        std.debug.print("err: {any}\n", .{err});
    }

    const client = Client.new(uri, &err) catch |e| {
        std.debug.print("Connected error: {any}", .{e});
        return;
    };
    if (err) {
        std.debug.print("err: {any}\n", .{err});
    }

    std.debug.print("client pointer: {any}\n", .{client.ptr});
}
