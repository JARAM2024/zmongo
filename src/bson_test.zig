const std = @import("std");
const bson = @import("bson.zig");

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
    std.debug.print("Json string: {s}\n", .{json.value}); // Json string: [ "Item 1", "Item 2" ]
}
