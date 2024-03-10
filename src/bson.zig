const std = @import("std");
const c = @import("c.zig").lib;

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

pub const Error = error{
    AppendError,
    BsonError,
    JsonError,
};

// BsonError wraps C bson_error_t which will be allocated in stack memory.
pub const BsonError = struct {
    const Self = @This();

    var bson_error: c.bson_error_t = undefined;

    pub fn init() BsonError {
        return BsonError{};
    }

    pub fn ptr(_: Self) *c.bson_error_t {
        return &bson_error;
    }

    pub fn message(_: Self) []const u8 {
        return std.mem.sliceTo(&bson_error.message, 0);
    }

    pub fn code(_: Self) u32 {
        return bson_error.code;
    }

    pub fn domain(_: Self) u32 {
        return bson_error.domain;
    }
};

pub const Json = struct {
    value: [*:0]u8, // pointer to C string.

    const Self = @This();

    pub fn free(self: *const Self) void {
        c.bson_free(self.value);
    }

    pub fn string(self: *const Self) []const u8 {
        return std.mem.sliceTo(self.value, 0);
    }
};

/// Bson is wrapper of c pointer to `bson_t` structure.
pub const Bson = struct {
    bson: c.bson_t, // pointer to C BSON struct

    const Self = @This();

    fn ptr(self: *Self) *c.bson_t {
        return &self.bson;
    }

    fn ptrConst(self: *const Self) *const c.bson_t {
        return &self.bson;
    }

    pub fn new() Self {
        const b = c.bson_new();
        return Bson{
            .bson = b.*,
        };
    }

    /// The newFromJson() function allocates and initializes a new bson_t by parsing the JSON found in data.
    /// Only a single JSON object may exist in data or an error will be set and NULL returned.
    ///
    /// A newly allocated bson_t if successful, otherwise NULL and error is set.
    pub fn newFromJson(data: [:0]const u8) !Bson {
        var err = BsonError.init();

        const bs = c.bson_new_from_json(data, -1, err.ptr());
        if (bs != null) {
            return Bson{
                .bson = bs.*,
            };
        } else {
            std.debug.print("newFromJson() failed: {s}\n", .{err.message()});
            return Error.BsonError;
        }
    }

    pub fn init(self: *Self) void {
        return c.bson_init(self.ptr());
    }

    pub fn deinit(self: *Self) void {
        return self.destroy();
    }

    pub fn destroy(self: *Self) void {
        c.bson_destroy(self.ptr());
    }

    pub fn appendInt32(self: *Self, key: [:0]const u8, value: i32) !void {
        if (!c.bson_append_int32(self.ptr(), key, -1, value))
            return Error.AppendError;
    }

    pub fn appendUtf8(self: *Self, key: [:0]const u8, value: [:0]const u8) !void {
        const ok = c.bson_append_utf8(self.ptr(), key, -1, value, -1);
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// encodes bson as a UTF-8 string using libbson’s legacy JSON format,
    /// except the outermost element is encoded as a JSON array, rather than a JSON document.
    /// The caller is responsible for freeing the resulting UTF-8 encoded string by
    /// calling bson_free() with the result.
    pub fn arrayAsJson(self: *Self) !Json {
        var l: usize = undefined;
        if (c.bson_array_as_json(self.ptr(), &l)) |str| {
            return Json{
                .value = str,
            };
        } else {
            return Error.JsonError;
        }
    }

    pub fn hasField(self: *Self, key: [:0]const u8) bool {
        return c.bson_has_field(self.ptrConst(), key);
    }

    /// The bson_append_array() function shall append array to bson using the specified key.
    /// The type of the field will be an array, but it is the responsibility of the caller
    /// to ensure that the keys of array are properly formatted with string keys such as “0”, “1”, “2” and so forth.
    pub fn appenArray(self: *Self, key: [:0]const u8, array: *const Bson) !void {
        const ok = c.bson_append_array(self.ptr(), key, -1, array.ptrConst());
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// The appendArrayBegin() function shall begin appending an array field to bson.
    /// This allows for incrementally building a sub-array.
    /// Doing so will generally yield better performance as you will serialize to a single buffer.
    /// When done building the sub-array, the caller MUST call bson_append_array_end().
    ///
    /// For generating array element keys, see bson_uint32_to_string().
    pub fn appendArrayBegin(self: *Self, key: [:0]const u8, child: *Bson) !void {
        const ok = c.bson_append_array_begin(self.ptr(), key, -1, child.ptr());
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    pub fn appendArrayEnd(self: *Self, child: *Bson) !void {
        const ok = c.bson_append_array_end(self.ptr(), child.ptr());
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendBinary() function shall append a new element to bson containing the binary data provided.
    /// https://mongoc.org/libbson/current/bson_append_binary.html
    pub fn appendBinary(self: *Self, key: [:0]const u8, binary: [:0]u8) !void {
        const ok = c.bson_append_array_begin(self.ptr(), key, -1, binary, -1);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// The appendDateTime() function shall append a new element to a bson document containing
    /// a date and time with no timezone information.
    /// Value is assumed to be in UTC format of milliseconds since the UNIX epoch. value MAY be negative.
    pub fn appendDateTime(self: *Self, key: [:0]const u8, value: i64) !void {
        const ok = c.bson_append_date_time(self.ptr(), key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendDocument() function shall append child to bson using the specified key.
    ///
    /// The type of the field will be a document.
    pub fn appendDocument(self: *Self, key: [:0]const u8, child: *Bson) !void {
        const ok = c.bson_append_document(self.ptr(), key, -1, child.ptrConst());
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendDocumentBegin() function shall begin appending a sub-document to bson.
    /// Use child to add fields to the sub-document.
    /// When completed, call appendDocumentEnd() to complete the element.
    ///
    /// child MUST be an uninitialized bson_t to avoid leaking memory.
    pub fn appendDocumentBegin(self: *Self, key: [:0]const u8, child: *Bson) !void {
        const ok = c.bson_append_document_begin(self.ptr(), key, -1, child.ptr());
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendDocumentEnd() function shall complete the appending of a document with appendDocumentBegin().
    ///
    /// child is invalid after calling this function.
    pub fn appendDocumentEnd(self: *Self, child: *Bson) !void {
        const ok = c.bson_append_document_end(self.ptr(), child.ptr());
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    ///The asCanonicalExtendedJson() encodes bson as a UTF-8 string in the canonical MongoDB Extended JSON format.
    ///
    ///The caller is responsible for freeing the resulting UTF-8 encoded string by calling bson_free() with the result.
    ///
    /// If non-NULL, length will be set to the length of the result in bytes.
    ///
    /// If successful, a newly allocated UTF-8 encoded string and length is set.
    /// Upon failure, NULL is returned.
    pub fn asCanonicalExtendedJson(self: *const Self) !Json {
        if (c.bson_as_canonical_extended_json(self.ptrConst(), null)) |json_str| {
            return Json{
                .value = json_str,
            };
        }

        return Error.BsonError;
    }
};
