const std = @import("std");
const bson = @import("bson.zig");

const datetime = @import("datetime.zig");

const testing = std.testing;

test "append array" {
    var b: bson.Bson = undefined;
    b.init();
    defer b.deinit();

    // fruits is bson array!
    var fruits: bson.Bson = undefined;
    fruits.init();
    defer fruits.deinit();

    try b.appenArray("groups", &fruits);
}

test "bson_as_json" {
    var b: bson.Bson = undefined;
    b.init();
    defer b.deinit();

    try b.appendUtf8("0", "Item 1");
    try b.appendUtf8("1", "Item 2");

    const json = try b.arrayAsJson();
    defer json.free();
    std.debug.print("Json string: {s}\n", .{json.string()}); // Json string: [ "Item 1", "Item 2" ]
}

test "creating bson document" {
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

    std.debug.print("json: \n{s}\n", .{json.string()});

    // {
    //      "born": {
    //          "$date": {
    //              "$numberLong": "-1990137600000"
    //          }
    //      },
    //      "died": {
    //          "$date": {
    //              "$numberLong": "694224000000"
    //          }
    //      },
    //      "name": {
    //          "first": "Grace",
    //          "last": "Hopper"
    //      },
    //      "degrees": [
    //          "BA",
    //          "Vassar"
    //      ]
    // }
    //
    //
}

test "json bson round trip" {
    const json_input =
        \\{
        \\ "born": {
        \\   "$date": {
        \\      "$numberLong": "-1990137600000"
        \\    }
        \\  },
        \\  "died": {
        \\    "$date": {
        \\      "$numberLong": "694224000000"
        \\    }
        \\  },
        \\  "name": {
        \\    "first": "Grace",
        \\    "last": "Hopper"
        \\  },
        \\  "degrees": [
        \\    "BA",
        \\    "Vassar"
        \\  ]
        \\}
    ;

    const document = try bson.Bson.newFromJson(json_input);

    const json_output = try document.asCanonicalExtendedJson();
    defer json_output.free();

    std.debug.print("json: \n{s}\n", .{json_output.string()});

    // try testing.expectEqualStrings(json_input, json_output.string());
}

test "oid round strip" {
    const oid = bson.Oid.init();

    const oid_string = try oid.toString(testing.allocator);

    defer testing.allocator.free(oid_string);

    std.debug.print("oid string: {s} - size: {d}\n", .{ oid_string, oid_string.len });

    const oid1 = bson.Oid.initFromString(oid_string[0..24 :0]);

    const oid1_string = try oid1.toString(testing.allocator);
    defer testing.allocator.free(oid1_string);

    std.debug.print("oid1 string: {s} - size: {d}\n", .{ oid1_string, oid1_string.len });

    // try testing.expectEqualSlices(u8, oid_string, oid1_string);
}
