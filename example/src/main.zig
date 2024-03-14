const std = @import("std");
const zmongo = @import("zmongo");
const mongo = zmongo.mongo;
const bson = zmongo.bson;
const datetime = zmongo.datetime;

pub fn main() !void {
    const uri_string = "mongodb://127.0.0.1:27017";

    mongo.init();
    defer mongo.cleanup();

    const uri = try mongo.Uri.new(uri_string);

    var err = bson.BsonError.init();
    var client: mongo.Client = undefined;
    if (mongo.Client.newFromUriWithError(uri, &err)) |cli| {
        client = cli;
    }

    const ok = client.setAppname("zmongo-test");
    if (!ok) {
        std.debug.print("setAppname() failed.\n", .{});
        return;
    }
    var command: bson.Bson = undefined;
    command.init();
    defer command.destroy();

    try command.appendInt32("ping", 1);

    var reply: bson.Bson = undefined;
    reply.init();
    defer reply.destroy();
    const read_prefs = mongo.ReadPrefs.init();
    defer read_prefs.destroy();

    const command_ok = client.commandSimple("fakedb", &command, read_prefs, &reply, &err);
    if (!command_ok) {
        std.debug.print("commandSimple() failed: {s}\n", .{err.string()});
        return;
    }

    var document = bson.Bson.new();
    // RFC3339 format: https://www.rfc-editor.org/rfc/rfc3339
    const born = try datetime.DateTime.parseRFC3339("1906-12-09T00:00:00Z");
    const died = try datetime.DateTime.parseRFC3339("1992-01-01T00:00:00Z");

    // append date-time
    try document.appendDateTime("born", born.unix(.milliseconds));
    try document.appendDateTime("died", died.unix(.milliseconds));

    // append child document
    var child: bson.Bson = undefined;
    child.init();
    defer child.deinit();
    try document.appendDocumentBegin("name", &child);
    try child.appendUtf8("first", "Grace");
    try child.appendUtf8("last", "Hopper");
    try document.appendDocumentEnd(&child);

    // append child array
    var arr: bson.Bson = undefined;
    arr.init();
    defer arr.deinit();
    try document.appendArrayBegin("degrees", &arr);
    try arr.appendUtf8("degree", "BA");
    try arr.appendUtf8("school", "Vassar");
    try document.appendArrayEnd(&arr);

    const json = try document.asCanonicalExtendedJson();
    defer json.free();

    std.debug.print("{s}", .{json.string()});
}
