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

/// Validates a BSON document by walking through the document and inspecting the keys and values for valid content.
/// You can modify how the validation occurs through the use of the flags parameter. A description of their effect is below.
/// BSON_VALIDATE_NONE Basic validation of BSON length and structure.
/// BSON_VALIDATE_UTF8 All keys and string values are checked for invalid UTF-8.
/// BSON_VALIDATE_UTF8_ALLOW_NULL String values are allowed to have embedded NULL bytes.
/// BSON_VALIDATE_DOLLAR_KEYS Prohibit keys that start with $ outside of a “DBRef” subdocument.
/// BSON_VALIDATE_DOT_KEYS Prohibit keys that contain . anywhere in the string.
/// BSON_VALIDATE_EMPTY_KEYS Prohibit zero-length keys.
/// Ref. https://mongoc.org/libbson/current/bson_validate_with_error.html
pub const ValidateFlags = enum(c_int) {
    BSON_VALIDATE_NONE = 0,
    BSON_VALIDATE_UTF8 = (1 << 0),
    BSON_VALIDATE_DOLLAR_KEYS = (1 << 1),
    BSON_VALIDATE_DOT_KEYS = (1 << 2),
    BSON_VALIDATE_UTF8_ALLOW_NULL = (1 << 3),
    BSON_VALIDATE_EMPTY_KEYS = (1 << 4),
};

pub const Time = struct {
    time: [*c]c.time_t,
};

pub const Timeval = struct {
    timeval: [*c]c.timeval,
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

pub const JsonMode = enum(c_uint) {
    BSON_JSON_MODE_LEGACY = 0,
    BSON_JSON_MODE_CANONICAL = 1,
    BSON_JSON_MODE_RELAXED = 2,
};

/// structure contains options for encoding BSON into MongoDB Extended JSON.
/// The mode member is a bson_json_mode_t defining the encoding mode.
/// The max_len member holds a maximum length for the resulting JSON string.
/// Encoding will stop once the serialised string has reached this length.
/// To encode the full BSON document, BSON_MAX_LEN_UNLIMITED can be used.
///
/// Ref. https://mongoc.org/libbson/current/bson_json_opts_t.html
pub const JsonOpts = struct {
    json_opts: ?*c.bson_json_opts_t,

    pub fn new(mode: JsonMode, max_len: i32) JsonOpts {
        const opts = c.bson_json_opts_new(mode, max_len);
        return JsonOpts{
            .json_opts = opts,
        };
    }

    pub fn destroy(self: JsonOpts) void {
        c.bson_json_opts_destroy(self.json_opts);
    }

    // TODO.
    // bson_json_opts_new()
    // bson_json_opts_destroy()
    // bson_json_opts_set_outermost_array()
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

    /// The appenInt32() function shall append a new element to a bson document of type i32.
    ///
    /// - bson: A Bson.
    /// - key: An ASCII C string containing the name of the field.
    /// - value: A i32 value to append.
    ///
    /// Returns true if the operation was applied successfully.
    /// The function will fail if appending value grows bson larger than INT32_MAX.
    ///
    /// bson_append_int32()
    /// Ref. https://mongoc.org/libbson/current/bson_append_int32.html
    pub fn appendInt32(self: *Bson, key: [:0]const u8, value: i32) !void {
        if (!c.bson_append_int32(self.ptr(), key, -1, value))
            return Error.AppendError;
    }

    /// The appenUtf8() function shall append a new element to a bson document of type UTF-8 string.
    ///
    /// - bson: A Bson.
    /// - key: An ASCII C string containing the name of the field.
    /// - value: A []const u8 value to append.
    ///
    /// Returns true if the operation was applied successfully.
    /// The function will fail if appending value grows bson larger than INT32_MAX.
    ///
    /// bson_append_utf8()
    /// Ref. https://mongoc.org/libbson/current/bson_append_utf8.html
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

    /// Checks to see if key contains an element named key.
    /// This also accepts “dotkey” notation such as “a.b.c.d”.
    ///
    /// - bson: A Bson.
    /// - key: A string containing the name of the field to check for.
    ///
    /// Returns true if key was found within bson; otherwise false.
    ///
    /// bson_has_field()
    /// Ref. https://mongoc.org/libbson/current/bson_has_field.html
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

    /// The appendOid() function shall append a new element to bson of type BSON_TYPE_OID.
    /// oid MUST be a pointer to a bson_oid_t.
    ///
    /// - bson: A bson_t.
    /// - key: An ASCII C string containing the name of the field.
    /// - key_length: The length of key in bytes, or -1 to determine the length with strlen().
    /// - oid: A bson_oid_t.
    ///
    /// Returns true if the operation was applied successfully. The function will fail if
    /// appending oid grows bson larger than INT32_MAX.
    ///
    /// bson_append_oid()
    /// Ref. https://mongoc.org/libbson/current/bson_append_oid.html
    pub fn appendOid(self: *Bson, key: [*c]const u8, oid: Oid) !void {
        const ok = c.bson_append_oid(self.bson, key, -1, oid.oid);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// The appendDouble() function shall append a new element to a bson document of type double.
    ///
    /// - bson: A Bson.
    /// - key: An ASCII C string containing the name of the field.
    /// - value: A f64 value to append.
    ///
    /// Returns true if the operation was applied successfully.
    /// The function will fail if appending value grows bson larger than INT32_MAX.
    ///
    /// bson_append_double()
    /// Ref. https://mongoc.org/libbson/current/bson_append_double.html
    pub fn appendDouble(self: *Bson, key: [*c]const u8, value: f64) !void {
        const ok = c.bson_append_double(self.bson, key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// The appenInt64() function shall append a new element to a bson document of type i64.
    ///
    /// - bson: A Bson.
    /// - key: An ASCII C string containing the name of the field.
    /// - value: A i64 value to append.
    ///
    /// Returns true if the operation was applied successfully.
    /// The function will fail if appending value grows bson larger than INT32_MAX.
    ///
    /// bson_append_int64()
    /// Ref. https://mongoc.org/libbson/current/bson_append_int64.html
    pub fn appendInt64(self: *Bson, key: [*c]const u8, value: i64) !void {
        const ok = c.bson_append_int64(self.bson, key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// The appenBool() function shall append a new element to a bson document of type bool.
    ///
    /// - bson: A Bson.
    /// - key: An ASCII C string containing the name of the field.
    /// - value: A bool value to append.
    ///
    /// Returns true if the operation was applied successfully.
    /// The function will fail if appending value grows bson larger than INT32_MAX.
    ///
    /// bson_append_bool()
    /// Ref. https://mongoc.org/libbson/current/bson_append_bool.html
    pub fn appendBool(self: *Bson, key: [*c]const 8, value: bool) !void {
        const ok = c.bson_append_bool(self.bson, key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// bson_append_now_utc()
    pub fn appendNowUtc(self: *Bson, key: [*c]const u8) !void {
        const ok = c.bson_append_now_utc(self.bson, key, -1);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// This function is not similar in functionality to appendDateTime().
    /// Timestamp elements are different in that they include only second precision and an increment field.
    /// They are primarily used for intra-MongoDB server communication.
    /// The appendTimestamp() function shall append a new element of type BSON_TYPE_TIMESTAMP.
    ///
    /// - bson: A bson_t.
    /// - key: An ASCII C string containing the name of the field.
    /// - timestamp: A u32.
    /// - increment: A u32.
    ///
    /// bson_append_timestamp()
    pub fn appendTimestamp(self: *Bson, key: [*c]const u8, timestamp: u32, increment: u32) !void {
        const ok = c.bson_append_timestamp(self.bson, key, -1, timestamp, increment);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// The appendTimeT() function is a helper that takes a time_t instead of milliseconds since the UNIX epoch.
    ///
    /// bson_append_time_t()
    pub fn appendTimeT(self: *Bson, key: [*c]u8, value: Time) !void {
        const ok = c.bson_append_time_t(self.bson, key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// The function shall append a new element to bson of type BSON_TYPE_NULL.
    ///
    /// bson_append_null()
    pub fn appendNull(self: *Bson, key: [*c]u8) !void {
        const ok = c.bson_append_null(self.bson, key, -1);
        if (!ok) {
            return Error.AppendError;
        }
        return;
    }

    /// The function is a helper that takes a struct timeval instead of milliseconds since the UNIX epoch.
    ///
    /// bson_append_timeval()
    pub fn appendTimeval(self: *Bson, key: [*c]u8, value: Timeval) !void {
        const ok = c.bson_append_timeval(self.bson, key, -1, value);
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// Appends a new field to bson by determining the boxed type in value.
    /// This is useful if you want to copy fields between documents but do not know the field type until runtime.
    ///
    /// bson_append_value()
    /// Ref. https://mongoc.org/libbson/current/bson_append_value.html
    pub fn appendValue(self: *Bson, key: [*c]const u8, value: Value) !void {
        const ok = c.bson_append_value(self.bson, key, -1, value.bson_value);
        if (!ok) {
            return Error.AppendError;
        }

        return;
    }

    /// The getData() function shall return the raw buffer of a bson document.
    /// This can be used in conjunction with the len property of a bson_t if you want to copy the raw buffer around.
    ///
    /// Returns a buffer which should not be modified or freed.
    ///
    /// bson_get_data()
    pub fn getData(self: *Bson) [*c]const u8 {
        return c.bson_get_data(self.bson);
    }

    /// The equal() function shall return true if both documents are equal.
    ///
    /// bson_equal()
    /// Ref. https://mongoc.org/libbson/current/bson_equal.html
    pub fn equal(self: *Bson, other: *Bson) bool {
        return c.bson_equal(self.bson, other.bson);
    }

    /// The compare() function shall compare two bson documents for equality.
    /// This can be useful in conjunction with _qsort()_.
    /// If equal, 0 is returned.
    ///
    /// Returns less than zero, zero, or greater than zero in qsort() style.
    ///
    /// bson_compare()
    /// Ref. https://mongoc.org/libbson/current/bson_compare.html
    pub fn compare(self: *Bson, other: *Bson) c_int {
        return c.bson_compare(self.bson, other.bson);
    }

    /// The initFromJson() function will initialize a new bson_t by parsing the JSON found in data.
    /// Only a single JSON object may exist in data or an error will be set and false returned.
    /// data should be in MongoDB Extended JSON format.
    ///
    /// bson_init_from_json()
    /// Ref. https://mongoc.org/libbson/current/bson_init_from_json.html
    pub fn initFromJson(self: *Bson, data: [*c]const u8) !void {
        var err = BsonError.init();
        const ok = c.bson_init_from_json(self.bson, data, -1, err.ptr());
        if (!ok) {
            std.debug.print("initFromJson failed(): {s}\n", .{err.string()});
            return Error.BsonError;
        }

        return;
    }

    /// Validates a BSON document by walking through the document and inspecting the keys and values for valid content.
    /// You can modify how the validation occurs through the use of the flags parameter, see validateWithError() for details.
    ///
    /// Returns true if bson is valid; otherwise false and offset is set to the byte offset where the error was detected.
    ///
    /// bson_validate()
    pub fn validate(self: *Bson, flags: ValidateFlags, offset: [*c]usize) bool {
        return c.bson_validate(self.bson, @intFromEnum(flags), offset);
    }

    /// Validates a BSON document by walking through the document and inspecting the keys and values for valid content.
    /// You can modify how the validation occurs through the use of the flags parameter. A description of their effect is below.
    /// BSON_VALIDATE_NONE Basic validation of BSON length and structure.
    /// BSON_VALIDATE_UTF8 All keys and string values are checked for invalid UTF-8.
    /// BSON_VALIDATE_UTF8_ALLOW_NULL String values are allowed to have embedded NULL bytes.
    /// BSON_VALIDATE_DOLLAR_KEYS Prohibit keys that start with $ outside of a “DBRef” subdocument.
    /// BSON_VALIDATE_DOT_KEYS Prohibit keys that contain . anywhere in the string.
    /// BSON_VALIDATE_EMPTY_KEYS Prohibit zero-length keys.
    ///
    /// Returns true if bson is valid; otherwise false and error is filled out.
    /// The bson_error_t domain is set to BSON_ERROR_INVALID. Its code is set to one of the bson_validate_flags_t flags
    /// indicating which validation failed; for example, if a key contains invalid UTF-8, then the code is set to BSON_VALIDATE_UTF8,
    /// but if the basic structure of the BSON document is corrupt, the code is set to BSON_VALIDATE_NONE.
    /// The error message is filled out, and gives more detail if possible.
    ///
    /// bson_validate_with_error()
    /// Ref. https://mongoc.org/libbson/current/bson_validate_with_error.html
    pub fn validateWithError(self: *Bson, flags: ValidateFlags, err: *BsonError) bool {
        return c.bson_validate_with_error(self.bson, @intFromEnum(flags), err.ptr());
    }

    /// The asJson() function shall encode bson as a UTF-8 string using libbson’s legacy JSON format.
    /// This function is superseded by asCanonicalExtendedJson() and asRelaxedExtendedJson(), which use the same
    /// MongoDB Extended JSON format as all other MongoDB drivers.
    /// The caller is responsible for freeing the resulting UTF-8 encoded string by calling bson_free() with the result.
    ///
    /// bson_as_json()
    /// Ref. https://mongoc.org/libbson/current/bson_as_json.html
    pub fn asJson(self: *Bson) [*c]u8 {
        return c.bson_as_json(self.bson, null);
    }

    /// The bson_as_json_with_opts() encodes bson as a UTF-8 string in the MongoDB Extended JSON format.
    /// The caller is responsible for freeing the resulting UTF-8 encoded string by calling bson_free() with the result.
    /// If non-NULL, length will be set to the length of the result in bytes.
    /// The opts structure is used to pass options for the encoding process. Please refer to the documentation of bson_json_opts_t for more details.
    ///
    /// Returns If successful, a newly allocated UTF-8 encoded string and length is set.
    /// Upon failure, NULL is returned.
    ///
    /// bson_as_json_with_opts()
    /// Ref. https://mongoc.org/libbson/current/bson_as_json_with_opts.html
    pub fn asJsonWithOpts(self: *Bson, opts: JsonOpts) [*c]u8 {
        return c.bson_as_json_with_opts(self.bson, null, opts.json_opts);
    }

    // TODO.
    // bson_new_from_buffer()
    // bson_new_from_data()
    // bson_append_code()
    // bson_append_code_with_scope()
    // bson_append_dbpointer()
    // bson_append_decimal128()
    // bson_append_iter()
    // bson_append_maxkey()
    // bson_append_minkey()
    // bson_append_regex()
    // bson_append_regex_w_len()
    // bson_append_symbol()
    // bson_append_undefined()
    // bson_array_as_canonical_extended_json()
    // bson_array_as_relaxed_extended_json()
    // bson_as_relaxed_extended_json()
    // bson_concat()
    // bson_copy()
    // bson_copy_to()
    // bson_copy_to_excluding()
    // bson_copy_to_excluding_noinit()
    // bson_copy_to_excluding_noinit_va()
    // bson_count_keys()
    // bson_destroy_with_steal()
    // bson_init_static()
    // bson_json_mode_t
    // bson_json_opts_t
    // bson_reinit()
    // bson_reserve_buffer()
    // bson_sized_new()
    // bson_steal()

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

/// The Value structure is a boxed type for encapsulating a runtime determined type.
/// Ref. https://mongoc.org/libbson/current/bson_value_t.html
pub const Value = struct {
    bson_value: [*c]c.bson_value_t,

    pub fn init() Value {
        return Value{
            .bson_value = null,
        };
    }

    pub fn copy(self: Value, dst: Value) void {
        c.bson_value_copy(self.bson_value, dst.bson_value);
    }

    pub fn destroy(self: Value) void {
        c.bson_value_destroy(self.bson_value);
    }
};
