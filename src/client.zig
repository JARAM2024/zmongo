const std = @import("std");
const c = @import("c.zig").lib;

const mongo = @import("mongo.zig");
const bson = @import("bson.zig");
const Uri = mongo.Uri;
const Error = mongo.Error;
const Collection = mongo.Collection;
const Database = mongo.Database;

const testing = std.testing;

pub const Client = struct {
    ptr: *c.mongoc_client_t,

    const Self = @This();

    pub fn new(uri: Uri) !Self {
        const err = bson.BsonError.init();
        const client = c.mongoc_client_new_from_uri_with_error(uri.ptr, err.ptr());
        if (client) |cli| {
            return Client{
                .ptr = cli,
            };
        }

        std.debug.print("Client.new() failed: {s}\n", .{err.message()});

        return Error.ClientError;
    }

    pub fn getServerStatus(self: Self) !void {
        const err = bson.BsonError.init();
        const reply: [*c]c.bson_t = c.bson_new();
        defer c.bson_destroy(reply);
        const read_prefs = c.mongoc_read_prefs_new(c.MONGOC_READ_PRIMARY);
        if (c.mongoc_client_get_server_status(self.ptr, read_prefs, reply, err.ptr())) {
            std.debug.print("server status here: ...\n{any}\n", .{reply});
        } else {
            std.debug.print("Get server status failed - code: {d} - domain: {d} - message: {s}\n", .{ err.code, err.domain, err.message });
            return Error.ClientError;
        }
    }

    pub fn setAppname(self: Self, appname: [:0]const u8) Error!void {
        if (!c.mongoc_client_set_appname(self.ptr, appname)) {
            return Error.ClientError;
        }

        return;
    }

    pub fn getDatabaseNames(self: Self) ![][]u8 {
        const err = bson.BsonError.init();
        if (c.mongoc_client_get_database_names(self.ptr, err.ptr())) |names| {
            std.debug.print("Database names OK>>>>{any}\n", .{names});
            return names;
        }

        std.debug.print("Client.getDatabaseNames() failed: {s}\n", .{err.message()});
        return Error.ClientError;
    }

    pub fn getCollection(self: Self, db: [:0]const u8, collection: [:0]const u8) !Collection {
        if (c.mongoc_client_get_collection(self.ptr, db, collection)) |col| {
            return Collection{
                .ptr = col,
            };
        }

        return Error.ClientError;
    }

    pub fn getDatabase(self: Self, name: [:0]const u8) !Database {
        if (c.mongoc_client_get_database(self.ptr, name)) |db| {
            return Database{
                .ptr = db,
            };
        }

        return Error.ClientError;
    }

    pub fn commandSimple(self: Self, db: [:0]const u8, command: *bson.Bson, read_prefs: ?*c.mongoc_read_prefs_t, reply: *bson.Bson) !void {
        const err = bson.BsonError.init();
        const ok = c.mongoc_client_command_simple(self.ptr, db, &command.value, read_prefs, &reply.value, err.ptr());
        errdefer reply.destroy();

        if (!ok) {
            std.debug.print("Client.commandSimple() failed: {s}\n", .{err.message()});
            return Error.ClientError;
        }

        return;
    }

    // ping connects to the server and do the hand shake.
    // It throws error if not successful.
    pub fn ping(self: Self) !void {
        var command: bson.Bson = undefined;
        command.init();
        defer command.destroy();

        try command.appendInt32("ping", 1);
        var reply: bson.Bson = undefined;
        reply.init();
        defer reply.destroy();

        try self.commandSimple("fakedb", &command, null, &reply);

        return;
    }
};
