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
pub const DeleteFlags = struct {
    pub const MONGOC_DELETE_NONE = c.MONGOC_DELETE_NONE;
    pub const MONGOC_DELETE_SINGLE_REMOVE = c.MONGOC_DELETE_SINGLE_REMOVE;
};

pub const InsertFlags = struct {
    pub const MONGOC_INSERT_NONE = c.MONGOC_INSERT_NONE;
    pub const MONGOC_INSERT_CONTINUE_ON_ERROR = c.MONGOC_INSERT_CONTINUE_ON_ERROR;
    pub const MONGOC_INSERT_NO_VALIDATE = c.MONGOC_INSERT_NO_VALIDATE;
};

pub const UpdateFlags = struct {
    pub const MONGOC_UPDATE_NONE = c.MONGOC_UPDATE_NONE;
    pub const MONGOC_UPDATE_UPSERT = c.MONGOC_UPDATE_UPSERT;
    pub const MONGOC_UPDATE_MULTI_UPDATE = c.MONGOC_UPDATE_MULTI_UPDATE;
    pub const MONGOC_UPDATE_NO_VALIDATE = c.MONGOC_UPDATE_NO_VALIDATE;
};

pub const WriteConcernLevels = struct {
    pub const MONGOC_WRITE_CONCERN_W_UNACKNOWLEDGED = c.MONGOC_WRITE_CONCERN_W_UNACKNOWLEDGED; // 0
    pub const MONGOC_WRITE_CONCERN_W_ERRORS_IGNORED = c.MONGOC_WRITE_CONCERN_W_ERRORS_IGNORED; // 1
    pub const MONGOC_WRITE_CONCERN_W_DEFAULT = c.MONGOC_WRITE_CONCERN_W_DEFAULT; // 2
    pub const MONGOC_WRITE_CONCERN_W_MAJORITY = c.MONGOC_WRITE_CONCERN_W_MAJORITY; // 3
    pub const MONGOC_WRITE_CONCERN_W_TAG = c.MONGOC_WRITE_CONCERN_W_TAG; // 4
    pub const MONGOC_WRITE_CONCERN_H = c.MONGOC_WRITE_CONCERN_H; // ""
};

pub const Uri = @import("uri.zig").Uri;
pub const Client = @import("client.zig").Client;
pub const Database = @import("database.zig").Database;
pub const Collection = @import("collection.zig").Collection;
pub const Host = @import("host.zig").Host;
pub const Cursor = @import("cursor.zig").Cursor;
pub const ReadPrefs = @import("read-prefs.zig").ReadPrefs;
pub const WriteConcern = @import("write-concern.zig").WriteConcern;
