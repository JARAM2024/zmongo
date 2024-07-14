const std = @import("std");
const c = @import("c.zig").lib;
const mongo = @import("mongo.zig");
const bson = @import("bson.zig");

/// `Cursor` provides access to a MongoDB query cursor. It wraps up the wire protocol negotiation
/// required to initiate a query and retrieve an unknown number of documents.
///
/// Common cursor operations include:
/// - Determine which host we’ve connected to with `Cursor.getHost()`.
/// - Retrieve more records with repeated calls to `Cursor.next()`.
/// - Clone a query to repeat execution at a later point with `Cursor.clone()`.
/// - Test for errors with `Cursor.error()`.
///
/// Cursors are lazy, meaning that no connection is established and no network traffic occurs until
/// the first call to `Cursor.next()`.
///
/// `Cursor` is NOT thread safe. It may only be used from within the thread in which it was created.
///
/// Ref. https://mongoc.org/libmongoc/current/mongoc_cursor_t.html
pub const Cursor = struct {
    cursor: ?*c.mongoc_cursor_t = undefined,

    /// init initializes Cursor to receive `mongoc_cursor_t`.
    /// It must be freed by calling `destroy` after use.
    pub fn init(cursor: ?*c.mongoc_cursor_t) Cursor {
        return Cursor{
            .cursor = cursor,
        };
    }

    /// This function free up memory held up by `mongoc_cursor_t`.
    /// mongoc_cursor_destroy()
    pub fn destroy(self: Cursor) void {
        c.mongoc_cursor_destroy(self.cursor);
    }

    pub fn deinit(self: Cursor) void {
        return self.destroy();
    }

    /// This function shall iterate the underlying cursor, setting bson to the next document.
    ///
    /// This function is a blocking function.
    ///
    /// It returns true if a valid bson document was read from the cursor.
    /// Otherwise, false if there was an error or the cursor was exhausted.
    /// Errors can be determined with the `Cursor.error()` function.
    ///
    /// mongoc_cursor_next()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_cursor_next.html
    pub fn next(self: Cursor, doc: *bson.Bson) bool {
        const doc_ptr = doc.ptrPtrConst();
        return c.mongoc_cursor_next(self.cursor, doc_ptr);
    }

    /// This function returns cursor message string if any.
    /// The caller must free memory after use.
    ///
    /// mongoc_cursor_error()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_cursor_error.html
    pub fn errorMessage(self: Cursor, allocator: std.mem.Allocator) ![]const u8 {
        var err: c.bson_error_t = undefined;
        const ok = c.mongoc_cursor_error(self.cursor, &err);
        if (!ok) {
            return mongo.Error.CursorError;
        }

        return allocator.dupeZ(u8, &err.message);
    }

    /// This function checks to see if an error has occurred while iterating the cursor.
    /// If an error occurred client-side, for example if there was a network error or timeout,
    /// or the cursor was created with invalid parameters, then reply is set to an empty BSON document.
    /// If an error occurred server-side, reply is set to the server’s reply document with
    /// information about the error.
    ///
    /// It returns false if no error has occurred, otherwise true and error is set.
    /// If the function returns true and reply is not NULL, then reply is set to a pointer to a BSON document,
    /// which is either empty or the server’s error response. The document is invalid after the cursor is freed
    /// with `Cursor.destroy()`.
    ///
    /// mongoc_cursor_error_document()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_cursor_error_document.html
    pub fn errorDocument(self: Cursor, err: bson.BsonError, reply: bson.Bson) bool {
        return c.mongoc_cursor_error_document(self.cursor, err.ptr(), &reply.ptrConst());
    }

    /// Fetches the MongoDB host that the cursor is communicating with in the host out parameter.
    ///
    /// mongoc_cursor_get_host()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_cursor_get_host.html
    pub fn getHost(self: Cursor, host: mongo.Host) void {
        return c.mongoc_cursor_get_host(self.cursor, host.ptr());
    }

    // mongoc_cursor_clone()
    // mongoc_cursor_current()
    // mongoc_cursor_get_batch_size()
    // mongoc_cursor_get_hint()
    // mongoc_cursor_get_id()
    // mongoc_cursor_get_limit()
    // mongoc_cursor_get_max_await_time_ms()
    // mongoc_cursor_is_alive()
    // mongoc_cursor_more()
    // mongoc_cursor_new_from_command_reply()
    // mongoc_cursor_new_from_command_reply_with_opts()
    // mongoc_cursor_set_batch_size()
    // mongoc_cursor_set_hint()
    // mongoc_cursor_set_limit()
    // mongoc_cursor_set_max_await_time_ms()
};
