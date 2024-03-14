const std = @import("std");
const c = @import("c.zig").lib;
const mongo = @import("mongo.zig");
const bson = @import("bson.zig");

/// WriteConcern tells the driver what level of acknowledgement to await from the server.
/// The default, MONGOC_WRITE_CONCERN_W_DEFAULT, is right for the great majority of applications.
///
/// You can specify a write concern on connection objects, database objects, collection objects,
/// or per-operation. Data-modifying operations typically use the write concern of the object
/// they operate on, and check the server response for a write concern error or write concern timeout.
/// For example, Collection.dropIndex() uses the collection’s write concern, and a write concern error
/// or timeout in the response is considered a failure.
///
/// Ref. https://mongoc.org/libmongoc/current/mongoc_write_concern_t.html
pub const WriteConcern = struct {
    write_concern: ?*c.mongoc_write_concern_t,

    pub fn ptrOrNull(self: WriteConcern) ?*c.mongoc_write_concern_t {
        return self.write_concern;
    }

    /// Creates a newly allocated write concern that can be configured based on user preference.
    /// This should be freed with mongoc_write_concern_destroy() when no longer in use.
    ///
    /// mongoc_write_concern_new()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_write_concern_new.html
    pub fn new() WriteConcern {
        return WriteConcern{
            .write_concern = c.mongoc_write_concern_new(),
        };
    }

    /// Frees all resources associated with the write concern structure.
    /// Does nothing if write_concern is NULL.
    ///
    /// mongoc_write_concern_destroy()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_write_concern_destroy.html
    pub fn destroy(self: WriteConcern) void {
        c.mongoc_write_concern_destroy(self.write_concern);
    }

    /// Sets the w value for the write concern. See mongoc_write_concern_t for more information on this setting.
    /// Unacknowledged writes are not causally consistent. If you execute a write operation with a
    /// WriteConcern on which you have called setW() with a value of 0, the write does not participate
    /// in causal consistency, even when executed with a Client.Session.
    ///
    /// mongoc_write_concern_set_w()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_write_concern_set_w.html
    pub fn setW(self: WriteConcern, w: mongo.WriteConcernLevels) void {
        c.mongoc_write_concern_set_w(self.write_concern, @intFromEnum(w));
    }

    /// Fetches the w parameter of the write concern.
    ///
    /// Returns an integer containing the w value. If wmajority is set,
    /// this would be MONGOC_WRITE_CONCERN_W_MAJORITY.
    ///
    /// mongoc_write_concern_get_w()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_write_concern_get_w.html
    pub fn getW(self: WriteConcern) i32 {
        return c.mongoc_write_concern_get_w(self.write_concern);
    }

    // TODO.
    // mongoc_write_concern_append()
    // mongoc_write_concern_copy()
    // mongoc_write_concern_get_fsync()
    // mongoc_write_concern_get_journal()
    // mongoc_write_concern_get_wmajority()
    // mongoc_write_concern_get_wtag()
    // mongoc_write_concern_get_wtimeout()
    // mongoc_write_concern_get_wtimeout_int64()
    // mongoc_write_concern_is_acknowledged()
    // mongoc_write_concern_is_default()
    // mongoc_write_concern_is_valid()
    // mongoc_write_concern_journal_is_set()
    // mongoc_write_concern_set_fsync()
    // mongoc_write_concern_set_journal()
    // mongoc_write_concern_set_wmajority()
    // mongoc_write_concern_set_wtag()
    // mongoc_write_concern_set_wtimeout()
    // mongoc_write_concern_set_wtimeout_int64()
};
