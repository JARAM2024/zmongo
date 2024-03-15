const std = @import("std");

const c = @import("c.zig").lib;
const mongo = @import("mongo.zig");
const bson = @import("bson.zig");
const datetime = @import("datetime.zig");
const testing = std.testing;

const allocator = testing.allocator;

//**********************************************************//
//              UNIT TESTS                                  //
// mongodb server expected to run and listen at             //
// 127.0.0.1:27017 (`bash libmongoc/mongodb-server.sh`)     //
//**********************************************************//

fn newClient() !mongo.Client {
    const uri_string = "mongodb://mongoadmin:mongopass@127.0.0.1:27017";
    const uri = try mongo.Uri.new(uri_string);

    var err = bson.BsonError.init();

    if (mongo.Client.newFromUriWithError(uri, &err)) |client| {
        return client;
    } else {
        std.debug.print("create client failed: {s}\n", .{err.string()});
        return mongo.Error.ClientError;
    }
}

test "init" {
    mongo.init();
}

test "uri parsing" {
    const uri_valid = "mongodb://127.0.0.1:27017";
    const uri_invalid = "fake_protocol://127.0.0.1:27018";

    _ = mongo.Uri.new(uri_invalid) catch |err| {
        try testing.expectEqual(mongo.Error.UriError, err);
    };

    _ = try mongo.Uri.new(uri_valid);
}

test "hello" {
    const client = try newClient();
    try client.setAppname("zmongo-test");

    var command: bson.Bson = undefined;
    std.debug.print("command type: {any}\n", .{@TypeOf(command)});
    command.init();
    defer command.destroy();

    var reply = bson.Bson.new();
    defer reply.destroy();
    const read_prefs = mongo.ReadPrefs.init();
    defer read_prefs.destroy();
    var err = bson.BsonError.init();

    std.debug.print("command type BEFORE: {any}\n", .{@TypeOf(command)});
    try command.appendInt32("ping", 1);

    const command_ok = client.commandSimple("fakedb", &command, read_prefs, &reply, &err);

    if (!command_ok) {
        std.debug.print("commandSimple() failed: {s} - server response: {any}\n", .{ err.string(), reply.asCanonicalExtendedJson() });
    }

    try testing.expect(command_ok);
}

test "ping" {
    const client = try newClient();
    const ping_ok = client.ping();
    try testing.expect(ping_ok);
}

test "Collection.insert" {
    const client = try newClient();

    var doc = bson.Bson.new();
    defer doc.destroy();
    try doc.appendUtf8("username", "Nikon Sugar");
    try doc.appendUtf8("email", "nikonsugar@example.com");
    try doc.appendUtf8("password", "SOMETHING_HASH_PASSWORD_HERE");
    const created = std.time.timestamp();
    try doc.appendDateTime("created", created);
    try doc.appendDateTime("udpated", created);

    const col = client.getCollection("db", "users");
    const write_concern = mongo.WriteConcern.new();
    // write_concern.setW(mongo.WriteConcernLevels.MONGOC_WRITE_CONCERN_W_DEFAULT);
    defer write_concern.destroy();

    // const opts = bson.Bson.new();
    // defer opts.destroy();
    // var reply = bson.Bson.new();
    // defer reply.destroy();

    var err = bson.BsonError.init();
    const ok = col.insert(&doc, mongo.InsertFlags.MONGOC_INSERT_NONE, write_concern, &err);
    // const ok = col.insertOne(&doc, &opts, &reply, &err);
    if (!ok) {
        std.debug.print("insert failed: {s}\n", .{err.string()});
    }

    try testing.expect(ok);
}

test "Collection.findWithOpts" {
    const client = try newClient();
    const col = client.getCollection("db", "users");

    var filter = bson.Bson.new();
    defer filter.destroy();
    var opts = bson.Bson.new();
    defer opts.destroy();
    const read_prefs = mongo.ReadPrefs.init();
    const cursor = col.findWithOpts(&filter, &opts, read_prefs);
    var doc = bson.Bson.new();
    defer doc.destroy();
    while (cursor.next(doc.ptrPtrConst())) {
        const json = try doc.asCanonicalExtendedJson();
        std.debug.print("{s}\n", .{json.string()});
    }
}

const Post = struct {
    title: []const u8,
    content: []const u8,
    created: i64,
    updated: i64,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator, title: []const u8, content: []const u8) !*Self {
        const post = try alloc.create(Post);

        post.title = title;
        post.content = content;
        post.created = std.time.timestamp();
        post.updated = std.time.timestamp();

        return post;
    }

    pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        return alloc.destroy(self);
    }
};

test "Collection.insertMany" {
    const client = try newClient();
    const col = client.getCollection("db", "posts");

    const post1 = try Post.init(allocator, "This is post one", "Here is my first post content");
    defer post1.deinit(allocator);
    const post1_json = try std.json.stringifyAlloc(allocator, post1, .{});
    defer allocator.free(post1_json);
    const p1 = try std.mem.Allocator.dupeZ(allocator, u8, post1_json);
    defer allocator.free(p1);

    const post2 = try Post.init(allocator, "This is post two", "Here is my second post content");
    defer post2.deinit(allocator);
    const post2_json = try std.json.stringifyAlloc(allocator, post2, .{});
    defer allocator.free(post2_json);
    const p2 = try std.mem.Allocator.dupeZ(allocator, u8, post2_json);
    defer allocator.free(p2);

    var bson1 = try bson.Bson.newFromJson(p1);
    defer bson1.destroy();
    var bson2 = try bson.Bson.newFromJson(p2);
    defer bson2.destroy();

    var posts = [_]*bson.Bson{ &bson1, &bson2 };
    var opts = bson.Bson.new();
    defer opts.deinit();
    var reply = bson.Bson.new();
    defer reply.deinit();
    var err = bson.BsonError.init();

    var ok = col.insertMany(posts[0..], posts.len, &opts, &reply, &err);
    if (!ok) {
        std.debug.print("insert post failed: {s}\n", .{err.string()});
    }

    // get them back
    var filter = bson.Bson.new();
    defer filter.destroy();
    const read_prefs = mongo.ReadPrefs.init();
    const cursor = col.findWithOpts(&filter, &opts, read_prefs);
    var doc = bson.Bson.new();
    defer doc.destroy();
    while (cursor.next(doc.ptrPtr())) {
        const json = try doc.asCanonicalExtendedJson();
        std.debug.print("{s}\n", .{json.string()});
    }

    // drop the collection
    ok = col.drop(&err);
    if (!ok) {
        std.debug.print("collection.drop() failed: {s}\n", .{err.string()});
    }

    try testing.expect(ok);
}

test "Collection.drop" {
    const client = try newClient();
    const col = client.getCollection("db", "users");
    var err = bson.BsonError.init();
    const ok = col.drop(&err);
    if (!ok) {
        std.debug.print("collection.drop() failed: {s}\n", .{err.string()});
    }
}

// TODO. insert more unit tests here just before `cleanup`...

// NOTE. call cleanup once at last otherwise `Segmentation fault`
test "cleanup" {
    mongo.cleanup();
}

//**************************** end unit tests **************************//
