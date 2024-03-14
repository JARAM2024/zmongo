const std = @import("std");
const c = @import("c.zig").lib;
const mongo = @import("mongo.zig");
const bson = @import("bson.zig");

pub const ReadPrefs = struct {
    read_prefs: ?*c.mongoc_read_prefs_t = null,

    /// mongoc_read_prefs_new()
    pub fn new(read_mode: mongo.ReadMode) ReadPrefs {
        return ReadPrefs{
            .read_prefs = c.mongoc_read_prefs_new(read_mode.ptr()),
        };
    }

    pub fn init() ReadPrefs {
        return ReadPrefs{
            .read_prefs = null,
        };
    }

    /// This function frees up memory held by ReadPrefs.
    /// mongoc_read_prefs_destroy()
    pub fn destroy(self: ReadPrefs) void {
        c.mongoc_read_prefs_destroy(self.read_prefs);
    }

    // This function returns pointer to `mongoc_read_prefs` or null.
    pub fn ptrOrNull(self: ReadPrefs) ?*c.mongoc_read_prefs_t {
        return self.read_prefs;
    }

    // TODO.
    // mongoc_read_prefs_copy()
    // mongoc_read_prefs_get_hedge()
    // mongoc_read_prefs_get_max_staleness_seconds()
    // mongoc_read_prefs_get_mode()
    // mongoc_read_prefs_get_tags()
    // mongoc_read_prefs_is_valid()
    // mongoc_read_prefs_set_hedge()
    // mongoc_read_prefs_set_max_staleness_seconds()
    // mongoc_read_prefs_set_mode()
    // mongoc_read_prefs_set_tags()
};
