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

pub const Json = struct {
    value: [*:0]u8, // pointer to C string.

    pub fn free(self: *const Json) void {
        c.bson_free(self.value);
    }

    pub fn string(self: *const Json) []const u8 {
        return std.mem.sliceTo(self.value, 0);
    }
};

/// Bson is wrapper of c pointer to `bson_t` structure.
pub const Bson = struct {
    bson: [*c]c.bson_t,

    /// The function shall create a new Bson structure on the heap.
    /// It should be freed with Bson.destroy() when it is no longer in use.
    ///
    /// bson_new()
    /// Ref. https://mongoc.org/libbson/current/bson_new.html
    pub fn new() Bson {
        return Bson{
            .bson = c.bson_new(), // [*c]c.bson_t
        };
    }

    pub fn ptr(self: *Bson) *c.bson_t {
        return self.bson;
    }

    pub fn ptrPtr(self: *Bson) [*c][*c]c.bson_t {
        return &self.bson;
    }

    pub fn ptrConst(self: *const Bson) [*c]const c.bson_t {
        return self.bson;
    }

    pub fn ptrPtrConst(self: *Bson) [*c][*c]const c.bson_t {
        return &self.bson;
    }

    /// The newFromJson() function allocates and initializes a new bson_t by parsing the JSON found in data.
    /// Only a single JSON object may exist in data or an error will be set and NULL returned.
    ///
    /// A newly allocated bson_t if successful, otherwise NULL and error is set.
    ///
    /// bson_new_from_json()
    pub fn newFromJson(data: [:0]const u8) !Bson {
        var err: c.bson_error_t = undefined;

        const bs = c.bson_new_from_json(data, -1, &err);
        if (bs != null) {
            return Bson{
                .bson = bs,
            };
        } else {
            std.debug.print("newFromJson() failed: {s}\n", .{err.message});
            return Error.BsonError;
        }
    }

    /// The init() function will create a new bson on **heap**.
    /// The caller must free it by calling `deinit()` or `destroy()` after use.
    ///
    /// **NOTE**: this API is different from `mongoc` API (ref. https://mongoc.org/libbson/current/bson_init.html)
    /// as in `mongoc` API, `bson_init()` will create bson in stack.
    ///
    /// bson_init()
    pub fn init(self: *Bson) void {
        // return c.bson_init(self.bson);
        self.bson = c.bson_new();
    }

    pub fn deinit(self: Bson) void {
        return self.destroy();
    }

    /// The destroy() function will free an allocated bson structure. It does nothing if
    /// `bson_t` is null.
    ///
    /// This function should always be called when you are done with `bson` structure.
    ///
    /// bson_destroy()
    /// Ref. https://mongoc.org/libbson/current/bson_destroy.html
    pub fn destroy(self: Bson) void {
        c.bson_destroy(self.bson);
    }

    /// bson_append_int32()
    pub fn appendInt32(self: *Bson, key: [:0]const u8, value: i32) !void {
        if (!c.bson_append_int32(self.ptr(), key, -1, value))
            return Error.AppendError;
    }

    /// The appendUtf8 function...
    ///
    /// bson_append_utf8()
    pub fn appendUtf8(self: *Bson, key: [:0]const u8, value: [:0]const u8) !void {
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
    ///
    /// bson_array_as_json()
    pub fn arrayAsJson(self: *Bson) !Json {
        var l: usize = undefined;
        if (c.bson_array_as_json(self.ptr(), &l)) |str| {
            return Json{
                .value = str,
            };
        } else {
            return Error.JsonError;
        }
    }

    /// The hasField() function...
    /// bson_has_field()
    pub fn hasField(self: *Bson, key: [:0]const u8) bool {
        return c.bson_has_field(self.ptrConst(), key);
    }

    /// The bson_append_array() function shall append array to bson using the specified key.
    /// The type of the field will be an array, but it is the responsibility of the caller
    /// to ensure that the keys of array are properly formatted with string keys such as “0”, “1”, “2” and so forth.
    ///
    /// bson_append_array()
    pub fn appenArray(self: *Bson, key: [:0]const u8, array: *const Bson) !void {
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
    ///
    /// bson_append_array_begin()
    pub fn appendArrayBegin(self: *Bson, key: [:0]const u8, child: *Bson) !void {
        const ok = c.bson_append_array_begin(self.ptr(), key, -1, child.ptr());
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// bson_append_array_end()
    pub fn appendArrayEnd(self: *Bson, child: *Bson) !void {
        const ok = c.bson_append_array_end(self.ptr(), child.ptr());
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendBinary() function shall append a new element to bson containing the binary data provided.
    /// https://mongoc.org/libbson/current/bson_append_binary.html
    ///
    /// bson_append_binary()
    pub fn appendBinary(self: *Bson, key: [:0]const u8, binary: [:0]u8) !void {
        const ok = c.bson_append_array_begin(self.ptr(), key, -1, binary, -1);
        if (!ok) {
            return Error.BsonError;
        }

        return;
    }

    /// The appendDateTime() function shall append a new element to a bson document containing
    /// a date and time with no timezone information.
    /// Value is assumed to be in UTC format of milliseconds since the UNIX epoch. value MAY be negative.
    ///
    /// bson_append_date_time()
    pub fn appendDateTime(self: *Bson, key: [:0]const u8, value: i64) !void {
        const ok = c.bson_append_date_time(self.ptr(), key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendDocument() function shall append child to bson using the specified key.
    ///
    /// The type of the field will be a document.
    ///
    /// bson_append_document()
    pub fn appendDocument(self: *Bson, key: [:0]const u8, child: *Bson) !void {
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
    ///
    /// bson_append_document_begin()
    pub fn appendDocumentBegin(self: *Bson, key: [:0]const u8, child: *Bson) !void {
        const ok = c.bson_append_document_begin(self.ptr(), key, -1, child.ptr());
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The appendDocumentEnd() function shall complete the appending of a document with appendDocumentBegin().
    ///
    /// child is invalid after calling this function.
    ///
    /// bson_append_document_end()
    pub fn appendDocumentEnd(self: *Bson, child: *Bson) !void {
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
    ///
    /// bson_as_canonical_extended_json()
    pub fn asCanonicalExtendedJson(self: *const Bson) !Json {
        if (c.bson_as_canonical_extended_json(self.ptrConst(), null)) |json_str| {
            return Json{
                .value = json_str,
            };
        }

        return Error.BsonError;
    }

    // bson_append_bool()
    // bson_append_code()
    // bson_append_code_with_scope()
    // bson_append_dbpointer()
    // bson_append_decimal128()
    // bson_append_double()
    // bson_append_int64()
    // bson_append_iter()
    // bson_append_maxkey()
    // bson_append_minkey()
    // bson_append_now_utc()
    // bson_append_null()
    // bson_append_oid()
    // bson_append_regex()
    // bson_append_regex_w_len()
    // bson_append_symbol()
    // bson_append_time_t()
    // bson_append_timestamp()
    // bson_append_timeval()
    // bson_append_undefined()
    // bson_append_value()
    // bson_array_as_canonical_extended_json()
    // bson_array_as_relaxed_extended_json()
    // bson_as_json()
    // bson_as_json_with_opts()
    // bson_as_relaxed_extended_json()
    // bson_compare()
    // bson_concat()
    // bson_copy()
    // bson_copy_to()
    // bson_copy_to_excluding()
    // bson_copy_to_excluding_noinit()
    // bson_copy_to_excluding_noinit_va()
    // bson_count_keys()
    // bson_destroy_with_steal()
    // bson_equal()
    // bson_get_data()
    // bson_init_from_json()
    // bson_init_static()
    // bson_json_mode_t
    // bson_json_opts_t
    // bson_new_from_buffer()
    // bson_new_from_data()
    // bson_reinit()
    // bson_reserve_buffer()
    // bson_sized_new()
    // bson_steal()
    // bson_validate()
    // bson_validate_with_error()

};

/// BsonError is a wrapper of `bson_error_t`  structure, which is used as
/// an out-parameter to pass error information to the caller.
/// It should be stack-allocated and does not requiring freeing.
///
/// https://mongoc.org/libbson/current/bson_error_t.html
pub const BsonError = struct {
    err: [*c]c.bson_error_t,

    var _err: c.bson_error_t = undefined;
    pub fn init() BsonError {
        return BsonError{
            .err = &_err, // NOTE. if setting to `undefined` then build with --release=safe get `Segmentation fault`!
        };
    }

    pub fn ptr(self: BsonError) [*c]c.bson_error_t {
        return self.err;
    }

    // Get error message if any. Caller must free return message after use.
    pub fn message(self: BsonError, alloc: std.mem.Allocator) ![]const u8 {
        return alloc.dupeZ(u8, self.err.message);
    }

    pub fn string(self: BsonError) []const u8 {
        return std.mem.sliceTo(&self.err.*.message, 0);
    }
};

// Bson Oid:
// =========

// Ref. https://mongoc.org/libbson/current/bson_oid_t.html
pub const Oid = struct {
    oid: [*c]c.bson_oid_t = null,

    // This function creates Oid and generates oid.
    pub fn init() Oid {
        var oid: c.bson_oid_t = undefined;
        c.bson_oid_init(@ptrCast(&oid), null);
        return Oid{
            .oid = @ptrCast(&oid),
        };
    }

    // This function create a new Oid with `undefined` oid.
    pub fn new() Oid {
        var oid: c.bson_oid_t = undefined;
        return Oid{
            .oid = &oid,
        };
    }

    // This function converts oid object to string.
    pub fn toString(self: Oid, alloc: std.mem.Allocator) ![]const u8 {
        var buf = try alloc.allocSentinel(u8, 24, 0);
        c.bson_oid_to_string(self.oid, buf[0..24 :0]);
        return buf[0..25];
    }

    // This function initiates oid from input string oid.
    pub fn initFromString(oid_string: [:0]const u8) Oid {
        const self = new();
        c.bson_oid_init_from_string(self.oid, oid_string);

        return self;
    }

    // TODO.
    // bson_oid_compare()
    // bson_oid_compare_unsafe()
    // bson_oid_copy()
    // bson_oid_copy_unsafe()
    // bson_oid_equal()
    // bson_oid_equal_unsafe()
    // bson_oid_get_time_t()
    // bson_oid_get_time_t_unsafe()
    // bson_oid_hash()
    // bson_oid_hash_unsafe()
    // bson_oid_init()
    // bson_oid_init_from_data()
    // bson_oid_init_from_string()
    // bson_oid_init_from_string_unsafe()
    // bson_oid_init_sequence()
    // bson_oid_is_valid()
    // bson_oid_to_string()
};
