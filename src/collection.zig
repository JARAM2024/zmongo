const std = @import("std");
const c = @import("c.zig").lib;

const bson = @import("bson.zig");
const mongo = @import("mongo.zig");
const Bson = bson.Bson;
const BsonError = bson.BsonError;
const UpdateFlags = mongo.UpdateFlags;
const DeleteFlags = mongo.DeleteFlags;
const InsertFlags = mongo.InsertFlags;
const QueryFlags = mongo.QueryFlags;
const WriteConcern = mongo.WriteConcern;
const ReadPrefs = mongo.ReadPrefs;
const Cursor = mongo.Cursor;

// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_t.html
pub const Collection = struct {
    collection: *c.mongoc_collection_t,

    /// This function shall insert document into collection.
    /// If no _id element is found in document, then a bson_oid_t will be generated locally and added to the document.
    /// If you must know the inserted document’s _id, generate it in your code and include it in the document.
    /// The _id you generate can be a bson_oid_t or any other non-array BSON type.
    ///
    /// Returns true if successful. Returns false and sets error if there are invalid arguments or a server or network error.
    /// A write concern timeout or write concern error is considered a failure.
    ///
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_insert.html
    /// mongoc_collection_insert()
    pub fn insert(self: Collection, document: *const Bson, flags: InsertFlags, write_concern: WriteConcern, err: *BsonError) bool {
        return c.mongoc_collection_insert(self.collection, @intFromEnum(flags), document.ptrConst(), write_concern.ptrOrNull(), err.ptr());
    }

    /// drop drops the current collection if it exists.
    ///
    /// mongoc_collection_drop()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_drop.html
    pub fn drop(self: Collection, err: *BsonError) bool {
        return c.mongoc_collection_drop(self.collection, err.ptr());
    }

    /// This function shall insert document into collection.
    /// To insert an array of documents, see insertMany().
    /// If no _id element is found in document, then a bson_oid_t will be generated locally and added to the document.
    /// If you must know the inserted document’s _id, generate it in your code and include it in the document.
    /// The _id you generate can be a bson_oid_t or any other non-array BSON type.
    ///
    /// If you pass a non-NULL reply, it is filled out with an “insertedCount” field.
    /// If there is a server error then reply contains either a “writeErrors” array with one subdocument or
    /// a “writeConcernErrors” array. The reply must be freed with bson_destroy().
    ///
    /// opts may be NULL or a BSON document with additional command options:
    /// - writeConcern: Construct a mongoc_write_concern_t and use mongoc_write_concern_append() to add the write concern to opts.
    ///     See the example code for mongoc_client_write_command_with_opts().
    /// - sessionId: First, construct a mongoc_client_session_t with mongoc_client_start_session().
    ///     You can begin a transaction with mongoc_client_session_start_transaction(),
    ///     optionally with a mongoc_transaction_opt_t that overrides the options inherited from collection,
    ///     and use mongoc_client_session_append() to add the session to opts. See the example code for mongoc_client_session_t.
    /// - validate: Construct a bitwise-or of all desired bson_validate_flags_t. Set to false to skip
    ///     client-side validation of the provided BSON documents.
    /// - comment: A bson_value_t specifying the comment to attach to this command. The comment will appear in
    ///     log messages, profiler output, and currentOp output. Requires MongoDB 4.4 or later.
    /// - bypassDocumentValidation: Set to true to skip server-side schema validation of the provided BSON documents.
    ///
    /// mongoc_collection_insert_one()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_insert_one.html
    // pub fn insertOne(self: Self, document: *const bson.Bson, opts: *const bson.Bson, reply: *bson.Bson, err: *bson.BsonError) bool {
    pub fn insertOne(self: Collection, document: *const Bson, opts: *const Bson, reply: *Bson, err: *BsonError) bool {
        return c.mongoc_collection_insert_one(self.collection, document.ptrConst(), opts.ptrConst(), reply.ptr(), err.ptr());
    }

    // mongoc_collection_insert_many()
    pub fn insertMany(self: Collection, documents: []*const Bson, comptime n: usize, opts: *const Bson, reply: *Bson, err: *BsonError) bool {
        var docs: [n][*c]const c.bson_t = undefined;
        for (documents, 0..) |doc, i| {
            docs[i] = doc.ptrConst();
        }

        return c.mongoc_collection_insert_many(self.collection, @ptrCast(docs[0..]), n, opts.ptrConst(), reply.ptr(), err.ptr());
    }

    /// Query on collection, passing arbitrary query options to the server in opts.
    /// To target a specific server, include an integer “serverId” field in opts with
    /// an id obtained first by calling `Client.selectServer()`,
    /// then `Server.descriptionId()` on its return value.
    ///
    /// - filter: bson containing the query to execute
    /// - opts: bson query options, including sort order and which fields to return. Can be `null`.
    /// - read_prefs: a ReadPrefs or null.
    ///
    /// Read preferences, read concern, and collation can be overridden by various sources.
    /// In a transaction, read concern and write concern are prohibited in opts and
    /// the read preference must be primary or NULL. The highest-priority sources for
    /// these options are listed first in the following table. No write concern is applied.
    ///
    /// This function is considered a retryable read operation. Upon a transient error
    /// (a network error, errors due to replica set failover, etc.) the operation is
    /// safely retried once. If retryreads is false in the URI the retry behavior does not apply.
    ///
    /// This function returns a newly allocated `Cursor` that should be freed with
    /// `Cursor.destroy()` when no longer in use.
    /// The returned `Cursor` is never NULL, even on error.
    /// The user must call `Cursor.next()` on the returned `Cursor` to
    /// execute the initial command. Cursor errors can be checked with
    /// `Cursor.errorDocument()`.
    /// It always fills out the bson_error_t if an error occurred, and
    /// optionally includes a server reply document if the error occurred server-side.
    ///
    /// Examples: TODO.
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_find_with_opts.html#examples
    ///
    /// mongoc_collection_find_with_opts()
    /// https://mongoc.org/libmongoc/current/mongoc_collection_find_with_opts.html
    pub fn findWithOpts(self: Collection, filter: *const Bson, opts: *const Bson, read_prefs: ReadPrefs) Cursor {
        const cursor = c.mongoc_collection_find_with_opts(self.collection, filter.ptrConst(), opts.ptrConst(), read_prefs.ptrOrNull());
        return Cursor.init(cursor);
    }

    /// This function shall delete documents in the given collection that match selector.
    /// The bson selector is not validated, simply passed along as appropriate to the server.
    /// As such, compatibility and errors should be validated in the appropriate server documentation.
    /// If you want to limit deletes to a single document, provide MONGOC_DELETE_SINGLE_REMOVE in flags.
    ///
    /// - flags: A mongo DeleteFlag
    /// - selector: bson containing query to match documents
    /// - write_concern: A mongo WriteConcern or null
    /// - err: Optional location for a bson error or null
    ///
    /// mongoc_collection_delete()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_delete.html
    pub fn delete(self: Collection, flags: DeleteFlags, selector: *const Bson, write_concern: WriteConcern, err: *BsonError) bool {
        return c.mongoc_collection_delete(self.collection, @intFromEnum(flags), selector.ptrConst(), write_concern.ptrOrNull(), err.ptr);
    }

    /// This function shall update documents in collection that match selector.
    ///
    /// By default, updates only a single document. Set flags to MONGOC_UPDATE_MULTI_UPDATE to update multiple documents.
    ///
    /// - collection: A mongoc_collection_t.
    /// - flags: A bitwise or of mongoc_update_flags_t.
    /// - selector: A bson_t containing the query to match documents for updating.
    /// - update: A bson_t containing the update to perform. If updating with a pipeline, a bson_t array.
    /// - write_concern: A mongoc_write_concern_t.
    /// - error: An optional location for a bson_error_t or NULL.
    ///
    /// mongoc_collection_update()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_update.html
    pub fn update(self: Collection, flags: UpdateFlags, selector: *const Bson, update_doc: *const Bson, write_concern: WriteConcern, err: *BsonError) bool {
        return c.mongoc_collection_update(self.collection, @intFromEnum(flags), selector.ptrConst(), update_doc.ptrConst(), write_concern.ptrOrNull(), err.ptr());
    }

    /// This function updates at most one document in collection that matches selector.
    /// To update multiple documents see mongoc_collection_update_many().
    /// If you pass a non-NULL reply, it is filled out with fields matchedCount, modifiedCount, and
    /// optionally upsertedId if applicable. If there is a server error then reply contains either a
    /// “writeErrors” array with one subdocument or a “writeConcernErrors” array. The reply must be freed with bson_destroy().
    ///
    /// - collection: A mongoc_collection_t.
    /// - selector: A bson_t containing the query to match the document for updating.
    /// -update: A bson_t containing the update to perform. If updating with a pipeline, a bson_t array.
    /// - reply: A maybe-NULL pointer to overwritable storage for a bson_t to contain the results.
    /// - error: An optional location for a bson_error_t or NULL.
    /// - opts may be NULL or a BSON document with additional command options:
    ///     + writeConcern: Construct a mongoc_write_concern_t and use mongoc_write_concern_append()
    ///     to add the write concern to opts. See the example code for mongoc_client_write_command_with_opts().
    ///     + sessionId: First, construct a mongoc_client_session_t with mongoc_client_start_session().
    ///     You can begin a transaction with mongoc_client_session_start_transaction(), optionally with a
    ///     mongoc_transaction_opt_t that overrides the options inherited from collection, and use
    ///     mongoc_client_session_append() to add the session to opts. See the example code for mongoc_client_session_t.
    ///     + validate: Construct a bitwise-or of all desired bson_validate_flags_t. Set to false to skip
    ///     client-side validation of the provided BSON documents.
    ///     + comment: A bson_value_t specifying the comment to attach to this command. The comment will appear in
    ///     log messages, profiler output, and currentOp output. Requires MongoDB 4.4 or later.
    ///     + bypassDocumentValidation: Set to true to skip server-side schema validation of the provided BSON documents.
    ///     + collation: Configure textual comparisons. See Setting Collation Order, and the MongoDB Manual entry on Collation.
    ///     Collation requires MongoDB 3.2 or later, otherwise an error is returned.
    ///     + hint: A document or string that specifies the index to use to support the query predicate.
    ///     + upsert: When true, creates a new document if no document matches the query.
    ///     + let: A BSON document consisting of any number of parameter names, each followed by definitions of constants in the
    ///     MQL Aggregate Expression language.
    ///     + arrayFilters: An array of filters specifying to which array elements an update should apply.
    ///
    /// Returns true if successful. Returns false and sets error if there are invalid arguments or a server or network error.
    /// A write concern timeout or write concern error is considered a failure
    ///
    /// mongoc_collection_update_one()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_update_one.html
    pub fn updateOne(self: Collection, selector: *const Bson, update_doc: *const Bson, opts: *const Bson, reply: *Bson, err: bson.BsonError) bool {
        return c.mongoc_collection_update_one(self.collection, selector.ptrConst(), update_doc.ptrConst(), opts.ptrConst(), reply.ptr(), err.ptr());
    }

    /// This function removes at most one document in the given collection that matches selector.
    /// To delete all matching documents, use mongoc_collection_delete_many().
    /// If you pass a non-NULL reply, it is filled out with the field “deletedCount”.
    /// If there is a server error then reply contains either a “writeErrors” array with one subdocument or a “writeConcernErrors” array.
    /// The reply must be freed with bson_destroy().
    ///
    /// - collection: A mongoc_collection_t.
    /// - selector: A bson_t containing the query to match documents.
    /// - reply: A maybe-NULL pointer to overwritable storage for a bson_t to contain the results.
    /// - error: An optional location for a bson_error_t or NULL.
    /// - opts may be NULL or a BSON document with additional command options:
    ///     + writeConcern: Construct a mongoc_write_concern_t and use mongoc_write_concern_append() to add the
    ///     write concern to opts. See the example code for mongoc_client_write_command_with_opts().
    ///     + sessionId: First, construct a mongoc_client_session_t with mongoc_client_start_session().
    ///     You can begin a transaction with mongoc_client_session_start_transaction(), optionally with a
    ///     mongoc_transaction_opt_t that overrides the options inherited from collection, and use
    ///     mongoc_client_session_append() to add the session to opts. See the example code for mongoc_client_session_t.
    ///     + validate: Construct a bitwise-or of all desired bson_validate_flags_t. Set to false to skip
    ///     client-side validation of the provided BSON documents.
    ///     + comment: A bson_value_t specifying the comment to attach to this command. The comment will appear in
    ///     log messages, profiler output, and currentOp output. Requires MongoDB 4.4 or later.
    ///     + collation: Configure textual comparisons. See Setting Collation Order, and the MongoDB Manual entry on Collation.
    ///     Collation requires MongoDB 3.2 or later, otherwise an error is returned.
    ///     + hint: A document or string that specifies the index to use to support the query predicate.
    ///     + let: A BSON document consisting of any number of parameter names, each followed by definitions of constants in the
    ///     MQL Aggregate Expression language.
    ///
    /// mongoc_collection_delete_one()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_delete_one.html
    pub fn deleteOne(self: Collection, selector: *const Bson, opts: *const Bson, reply: *Bson, err: *BsonError) bool {
        return c.mongoc_collection_delete_one(self.collection, selector.ptrConst(), opts.ptrConst(), reply.ptr(), err.ptr());
    }

    /// This function returns a newly allocated mongoc_cursor_t that should be freed with mongoc_cursor_destroy() when no longer in use.
    /// The returned mongoc_cursor_t is never NULL, even on error. The user must call mongoc_cursor_next()
    /// on the returned mongoc_cursor_t to execute the initial command.
    ///
    /// This function is not considered a retryable read operation.
    ///
    /// - collection: A mongoc_collection_t.
    /// - flags: A mongoc_query_flags_t.
    /// - skip: A uint32_t with the number of documents to skip or zero.
    /// - limit: A uint32_t with the max number of documents to return or zero.
    /// - batch_size: A uint32_t with the number of documents in each batch or zero. Default is 100.
    /// - command: A bson_t containing the command to execute.
    /// - fields: A bson_t containing the fields to return or NULL. Not all commands support this option.
    /// - read_prefs: An optional mongoc_read_prefs_t. Otherwise, the command uses mode MONGOC_READ_PRIMARY.
    ///
    /// Cursor errors can be checked with mongoc_cursor_error_document(). It always fills out the bson_error_t
    /// if an error occurred, and optionally includes a server reply document if the error occurred server-side.
    ///
    /// mongoc_collection_command()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_command.html
    pub fn command(self: Collection, flags: QueryFlags, skip: u32, limit: u32, batch_size: u32, command_doc: *const Bson, fields: *const Bson, read_prefs: ReadPrefs) Cursor {
        const cursor = c.mongoc_collection_command(self.collection, @intFromEnum(flags), skip, limit, batch_size, command_doc.ptrConst(), fields.ptrConst(), read_prefs.ptrOrNull());

        return Cursor.init(cursor);
    }

    /// This is a simplified version of mongoc_collection_command() that returns the first result document in reply.
    /// The collection’s read preference, read concern, and write concern are not applied to the command.
    /// The parameter reply is initialized even upon failure to simplify memory management.
    ///
    /// This function tries to unwrap an embedded error in the command when possible.
    /// The unwrapped error will be propagated via the error parameter. Additionally, the result document is set in reply.
    ///
    /// - collection: A mongoc_collection_t.
    /// - command: A bson_t containing the command to execute.
    /// - read_prefs: An optional mongoc_read_prefs_t. Otherwise, the command uses mode MONGOC_READ_PRIMARY.
    /// - reply: A maybe-NULL pointer to overwritable storage for a bson_t to contain the results.
    /// - error: An optional location for a bson_error_t or NULL.
    ///
    /// This function is not considered a retryable read operation.
    ///
    /// mongoc_collection_command_simple()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_command_simple.html
    pub fn commandSimple(self: Collection, command_doc: *const Bson, read_prefs: ReadPrefs, reply: *Bson, err: *BsonError) Cursor {
        const cursor = c.mongoc_collection_command_simple(self.collection, command_doc.ptrConst(), read_prefs.ptrOrNull, reply.ptr(), err.ptr());
        return Cursor.init(cursor);
    }

    ///
    /// Execute a command on the server, interpreting opts according to the MongoDB server version.
    /// To send a raw command to the server without any of this logic, use mongoc_client_command_simple().
    ///
    /// Read preferences, read and write concern, and collation can be overridden by various sources.
    /// The highest-priority sources for these options are listed first:
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_command_with_opts.html
    ///
    /// In a transaction, read concern and write concern are prohibited in opts and the read preference must be primary or NULL.
    /// See the example for transactions and for the “distinct” command with opts.
    ///
    /// - collection: A mongoc_collection_t.
    /// - command: A bson_t containing the command specification.
    /// - read_prefs: An optional mongoc_read_prefs_t.
    /// - opts: A bson_t containing additional options.
    ///     + reply: A maybe-NULL pointer to overwritable storage for a bson_t to contain the results.
    ///     + error: An optional location for a bson_error_t or NULL.
    ///     + opts may be NULL or a BSON document with additional command options:
    ///     + readConcern: Construct a mongoc_read_concern_t and use mongoc_read_concern_append() to add the read concern to opts.
    ///     See the example code for mongoc_client_read_command_with_opts(). Read concern requires MongoDB 3.2 or later, otherwise an error is returned.
    ///     + writeConcern: Construct a mongoc_write_concern_t and use mongoc_write_concern_append() to add the write concern to opts.
    ///     See the example code for mongoc_client_write_command_with_opts().
    ///     + sessionId: First, construct a mongoc_client_session_t with mongoc_client_start_session().
    ///     You can begin a transaction with mongoc_client_session_start_transaction(), optionally with a
    ///     mongoc_transaction_opt_t that overrides the options inherited from collection, and use mongoc_client_session_append()
    ///     to add the session to opts. See the example code for mongoc_client_session_t.
    ///     + collation: Configure textual comparisons. See Setting Collation Order, and the MongoDB Manual entry on Collation.
    ///     Collation requires MongoDB 3.2 or later, otherwise an error is returned.
    ///     + serverId: To target a specific server, include an int32 “serverId” field. Obtain the id by calling
    ///     mongoc_client_select_server(), then mongoc_server_description_id() on its return value.
    ///
    /// reply is always initialized, and must be freed with bson_destroy().
    ///
    /// mongoc_collection_command_with_opts()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_collection_command_with_opts.html
    pub fn commandWithOpts(self: Collection, command_doc: *const Bson, read_prefs: ReadPrefs, opts: *const Bson, reply: *Bson, err: *BsonError) bool {
        return c.mongoc_collection_command_with_opts(self.collection, command_doc.ptrConst(), read_prefs.ptrOrNull(), opts.ptrConst(), reply.ptr(), err.ptr());
    }

    // mongoc_collection_update_many()
    // mongoc_collection_delete_many()
    // mongoc_collection_count_documents()
    // mongoc_collection_find_and_modify()
    // mongoc_collection_find_and_modify_with_opts()

    // mongoc_collection_aggregate()
    // mongoc_collection_copy()
    // mongoc_collection_estimated_document_count()
    // mongoc_collection_count()
    // mongoc_collection_count_with_opts()
    // mongoc_collection_create_bulk_operation()
    // mongoc_collection_create_bulk_operation_with_opts()
    // mongoc_collection_create_index()
    // mongoc_collection_create_index_with_opts()
    // mongoc_collection_create_indexes_with_opts()
    // mongoc_collection_destroy()
    // mongoc_collection_drop_index()
    // mongoc_collection_drop_index_with_opts()
    // mongoc_collection_drop_with_opts()
    // mongoc_collection_ensure_index()
    // mongoc_collection_get_last_error()
    // mongoc_collection_get_name()
    // mongoc_collection_get_read_concern()
    // mongoc_collection_get_read_prefs()
    // mongoc_collection_get_write_concern()
    // mongoc_collection_insert_bulk()
    // mongoc_collection_keys_to_index_string()
    // mongoc_collection_read_command_with_opts()
    // mongoc_collection_read_write_command_with_opts()
    // mongoc_collection_remove()
    // mongoc_collection_rename()
    // mongoc_collection_rename_with_opts()
    // mongoc_collection_replace_one()
    // mongoc_collection_save()
    // mongoc_collection_set_read_concern()
    // mongoc_collection_set_read_prefs()
    // mongoc_collection_set_write_concern()
    // mongoc_collection_stats()
    // mongoc_collection_validate()
    // mongoc_collection_write_command_with_opts()

    // mongoc_collection_find() - Deprecated. DO NOT USE. Use find_with_opts() instead!
    // mongoc_collection_find_indexes() - Deprecated. DO NOT USE
    // mongoc_collection_find_indexes_with_opts() - Deprecated. DO NOT USE
};
