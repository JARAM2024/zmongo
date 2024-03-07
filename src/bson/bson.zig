const c = @cImport({
    @cInclude("bson.h");
});

const std = @import("std");

pub const Type = struct {
    pub const EOD: c_uint = c.BSON_TYPE_EOD;
    pub const DOUBLE: c_uint = c.BSON_TYPE_DOUBLE;
    pub const UTF8: c_uint = c.BSON_TYPE_UTF8;
    pub const DOCUMENT: c_uint = c.BSON_TYPE_DOCUMENT;
    pub const ARRAY: c_uint = c.BSON_TYPE_ARRAY;
    pub const BINARY: c_uint = c.BSON_TYPE_BINARY;
    pub const UNDEFINED: c_uint = c.BSON_TYPE_UNDEFINED;
    pub const OID: c_uint = c.BSON_TYPE_OID;
    pub const BOOL: c_uint = c.BSON_TYPE_BOOL;
    pub const DATE_TIME: c_uint = c.BSON_TYPE_DATE_TIME;
    pub const NULL: c_uint = c.BSON_TYPE_NULL;
    pub const REGEX: c_uint = c.BSON_TYPE_REGEX;
    pub const DBPOINTER: c_uint = c.BSON_TYPE_DBPOINTER;
    pub const CODE: c_uint = c.BSON_TYPE_CODE;
    pub const SYMBOL: c_uint = c.BSON_TYPE_SYMBOL;
    pub const CODEWSCOPE: c_uint = c.BSON_TYPE_CODEWSCOPE;
    pub const INT32: c_uint = c.BSON_TYPE_INT32;
    pub const TIMESTAMP: c_uint = c.BSON_TYPE_TIMESTAMP;
    pub const INT64: c_uint = c.BSON_TYPE_INT64;
    pub const DECIMAL128: c_uint = c.BSON_TYPE_DECIMAL128;
    pub const MAXKEY: c_uint = c.BSON_TYPE_MAXKEY;
    pub const MINKEY: c_uint = c.BSON_TYPE_MINKEY;
};

pub const BsonError = struct{
    ptr: c.bson_err_t,
}

pub const Json = struct {
    value: [*:0]u8, // pointer to C string.

    pub fn free(self: *const Json) void {
        c.bson_free(self.value);
    }
};

/// Bson is wrapper of c pointer to `bson_t` structure.
pub const Bson = struct {
    ptr: [*c]c.bson_t, // pointer to C BSON struct

    const Self = @This();

    /// `init` initializes a bson_t that is placed on the heap.
    /// It should be freed with `deinit()` when no long in use.
    /// NOTE. `init` ~ `bson_new` in libbson.
    pub fn init() Self {
        const b = c.bson_new();

        return Self{
            .ptr = b,
        };
    }

    pub fn deinit(self: Self) void {
        c.bson_destroy(self.ptr);
    }

    /// The bson_append_array() function shall append array to bson using the specified key.
    /// The type of the field will be an array, but it is the responsibility of the caller
    /// to ensure that the keys of array are properly formatted with string keys such as “0”, “1”, “2” and so forth.
    pub fn appenArray(self: Self, key: [:0]const u8, array: Bson) !void {
        const ok = c.bson_append_array(self.ptr, key, -1, array.ptr);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// The bson_append_array_begin() function shall begin appending an array field to bson.
    /// This allows for incrementally building a sub-array.
    /// Doing so will generally yield better performance as you will serialize to a single buffer.
    /// When done building the sub-array, the caller MUST call bson_append_array_end().
    ///
    /// For generating array element keys, see bson_uint32_to_string().
    pub fn appendArrayBegin(self: Self, key: [:0]const u8, child: Bson) !void {
        const ok = c.bson_append_array_begin(self.ptr, key, -1, child.ptr);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    pub fn appendArrayEnd(self: Self, child: Bson) !void {
        const ok = c.bson_append_array_end(self.ptr, child.ptr);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// appends a new element to bson containing the binary data provided.
    /// https://mongoc.org/libbson/current/bson_append_binary.html
    pub fn appendBinary(self: Self, key: [:0]const u8, binary: [:0]u8) !void {
        const ok = c.bson_append_array_begin(self.ptr, key, -1, binary, -1);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    pub fn appendUtf8(self: Self, key: [:0]const u8, value: [:0]const u8) !void {
        const ok = c.bson_append_utf8(self.ptr, key, -1, value, -1);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// encodes bson as a UTF-8 string using libbson’s legacy JSON format,
    /// except the outermost element is encoded as a JSON array, rather than a JSON document.
    /// The caller is responsible for freeing the resulting UTF-8 encoded string by
    /// calling bson_free() with the result.
    pub fn arrayAsJson(self: Self) !Json {
        var l: usize = undefined;
        if (c.bson_array_as_json(self.ptr, &l)) |value| {
            return Json{
                .value = value,
            };
        } else {
            return Error.BsonError;
        }
    }
};

pub const Error = error{
    BsonError,
    JsonError,
};

test "append array" {
    const b = Bson.init();
    defer b.deinit();

    // fruits is bson array!
    const fruits = Bson.init();
    defer fruits.deinit();

    try b.appenArray("groups", fruits);
}

test "bson_as_json" {
    const b = Bson.init();
    try b.appendUtf8("0", "Item 1");
    try b.appendUtf8("1", "Item 2");

    const json = try b.arrayAsJson();
    defer json.free();
    std.debug.print("Json string: {s}\n", .{json.value}); // Json string: [ "Item 1", "Item 2" ]
}
