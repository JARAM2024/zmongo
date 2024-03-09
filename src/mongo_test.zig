const std = @import("std");

const mongo = @import("mongo.zig");
const bson = @import("bson.zig");
const testing = std.testing;

//**********************************************************//
//              UNIT TESTS                                  //
//**********************************************************//
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
    const uri_string = "mongodb://127.0.0.1:27017";

    const uri = try mongo.Uri.new(uri_string);
    const client = try mongo.Client.new(uri);

    try client.setAppname("zmongo-test");
    var command: bson.Bson = undefined;
    command.init();
    defer command.destroy();

    try command.appendInt32("ping", 1);

    var reply: bson.Bson = undefined;
    reply.init();
    defer reply.destroy();

    try client.commandSimple("fakedb", &command, null, &reply);
    try testing.expect(reply.hasField("ok"));
}

test "ping" {
    const uri_string = "mongodb://127.0.0.1:27017";

    const uri = try mongo.Uri.new(uri_string);
    const client = try mongo.Client.new(uri);

    try client.ping();
}

// TODO. insert more unit tests here just before `cleanup`...

// NOTE. call cleanup once at last otherwise `Segmentation fault`
test "cleanup" {
    mongo.cleanup();
}

//**************************** end unit tests **************************//
