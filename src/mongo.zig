const c = @import("c.zig").lib;

pub fn init() void {
    return c.mongoc_init();
}

pub fn cleanup() void {
    c.mongoc_cleanup();
    return;
}

pub const Error = error{
    MongoError,
    UriError,
    ClientError,
    DatabaseError,
    CollectionError,
    CursorError,
    ReadPrefsError,
};

// Ref. https://mongoc.org/libmongoc/current/mongoc_delete_flags_t.html
pub const DeleteFlags = enum(c_uint) {
    MONGOC_DELETE_NONE = 0,
    MONGOC_DELETE_SINGLE_REMOVE = 1 << 0,
};

// Ref. https://mongoc.org/libmongoc/current/mongoc_insert_flags_t.html
pub const InsertFlags = enum(c_uint) {
    MONGOC_INSERT_NONE = 0,
    MONGOC_INSERT_CONTINUE_ON_ERROR = 1 << 0,
};

// Ref. https://mongoc.org/libmongoc/current/mongoc_update_flags_t.html
pub const UpdateFlags = enum(c_uint) {
    MONGOC_UPDATE_NONE = 0,
    MONGOC_UPDATE_UPSERT = 1 << 0,
    MONGOC_UPDATE_MULTI_UPDATE = 1 << 1,
};

// Ref. https://mongoc.org/libmongoc/current/mongoc_query_flags_t.html
pub const QueryFlags = enum(c_uint) {
    MONGOC_QUERY_NONE = 0,
    MONGOC_QUERY_TAILABLE_CURSOR = 1 << 1,
    MONGOC_QUERY_SECONDARY_OK = 1 << 2,
    MONGOC_QUERY_OPLOG_REPLAY = 1 << 3,
    MONGOC_QUERY_NO_CURSOR_TIMEOUT = 1 << 4,
    MONGOC_QUERY_AWAIT_DATA = 1 << 5,
    MONGOC_QUERY_EXHAUST = 1 << 6,
    MONGOC_QUERY_PARTIAL = 1 << 7,
};

pub const WriteConcernLevels = enum(i32) {
    MONGOC_WRITE_CONCERN_W_UNACKNOWLEDGED = 0,
    MONGOC_WRITE_CONCERN_W_ERRORS_IGNORED = 1,
    MONGOC_WRITE_CONCERN_W_DEFAULT = 2,
    MONGOC_WRITE_CONCERN_W_MAJORITY = 3,
    MONGOC_WRITE_CONCERN_W_TAG = 4,
    // pub const MONGOC_WRITE_CONCERN_H = c.MONGOC_WRITE_CONCERN_H; // ""
};

pub const Uri = @import("uri.zig").Uri;
pub const Client = @import("client.zig").Client;
pub const Database = @import("database.zig").Database;
pub const Collection = @import("collection.zig").Collection;
pub const Host = @import("host.zig").Host;
pub const Cursor = @import("cursor.zig").Cursor;
pub const ReadPrefs = @import("read-prefs.zig").ReadPrefs;
pub const WriteConcern = @import("write-concern.zig").WriteConcern;
