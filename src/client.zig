const std = @import("std");
const c = @import("c.zig").lib;

const mongo = @import("mongo.zig");
const bson = @import("bson.zig");
const Uri = mongo.Uri;
const ReadPrefs = mongo.ReadPrefs;
const Bson = bson.Bson;
const BsonError = bson.BsonError;

const Error = mongo.Error;
const Collection = mongo.Collection;
const Database = mongo.Database;

const testing = std.testing;

// Ref. https://mongoc.org/libmongoc/current/mongoc_client_t.html
pub const Client = struct {
    client: ?*c.mongoc_client_t,

    /// Creates a new mongoc_client_t using the URI string provided.
    ///
    /// A newly allocated mongoc_client_t that should be freed with mongoc_client_destroy()
    /// when no longer in use. On error, NULL is returned and an error or warning will be logged.
    ///
    /// mongoc_client_new()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_new.html
    pub fn new(uri_string: []const u8) ?Client {
        const cli = c.mongoc_client_new(uri_string);

        if (cli == null) {
            return null;
        }

        return Client{
            .client = cli,
        };
    }

    /// Creates a new Client using the Uri provided.
    ///
    /// A newly allocated mongoc_client_t that should be freed with mongoc_client_destroy()
    /// when no longer in use. On error, NULL is returned and an error or warning will be logged.
    ///
    // mongoc_client_new_from_uri_with_error()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_new_from_uri_with_error.html
    pub fn newFromUriWithError(uri: Uri, err: *bson.BsonError) ?Client {
        const cli = c.mongoc_client_new_from_uri_with_error(uri.ptr, err.ptr());

        if (cli == null) {
            return null;
        }

        return Client{
            .client = cli,
        };
    }

    /// Creates a new Client using the Uri provided.
    ///
    /// A newly allocated mongoc_client_t that should be freed with mongoc_client_destroy()
    /// when no longer in use. On error, NULL is returned and an error or warning will be logged.
    ///
    // mongoc_client_new_from_uri()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_new_from_uri_with_error.html
    pub fn newFromUri(uri: Uri) ?Client {
        const cli = c.mongoc_client_new_from_uri(uri.ptr);

        if (cli == null) {
            return null;
        }

        return Client{
            .client = cli,
        };
    }

    /// Queries the server for the current server status. The result is stored in reply.
    ///
    /// reply is always initialized, even in the case of failure. Always call bson_destroy() to release it.
    ///
    /// mongoc_client_get_server_status()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_get_server_status.html
    pub fn getServerStatus(self: Client, read_prefs: ReadPrefs, reply: *Bson, err: *BsonError) bool {
        return c.mongoc_client_get_server_status(self.client, read_prefs.ptrOrNull, reply.ptr(), err.ptr());
    }

    /// Sets the application name for this client. This string, along with other internal driver details,
    /// is sent to the server as part of the initial connection handshake (“hello”).
    /// appname is copied, and doesn’t have to remain valid after the call to mongoc_client_set_appname().
    ///
    /// This function will log an error and return false in the following cases:
    /// - appname is longer than MONGOC_HANDSHAKE_APPNAME_MAX
    /// - client has already initiated a handshake
    /// - client is from a mongoc_client_pool_t
    ///
    /// - client: A mongoc_client_t.
    /// - appname: The application name, of length at most MONGOC_HANDSHAKE_APPNAME_MAX.
    ///
    /// It returns true if the appname is set successfully. Otherwise, false.
    ///
    /// mongoc_client_set_appname()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_set_appname.html
    pub fn setAppname(self: Client, appname: []const u8) !void {
        const ok = c.mongoc_client_set_appname(self.client, @ptrCast(appname));
        if (!ok) {
            return Error.ClientError;
        }

        return;
    }

    /// Get a newly allocated mongoc_collection_t for the collection named collection in the database named db.
    ///
    /// NOTE. Collections are automatically created on the MongoDB server upon insertion of the first document.
    /// There is no need to create a collection manually.
    ///
    /// - client: A mongoc_client_t.
    /// - db: The name of the database containing the collection.
    /// - collection: The name of the collection.
    ///
    /// A newly allocated mongoc_collection_t that should be freed with mongoc_collection_destroy() when no longer in use.
    ///
    /// mongoc_client_get_collection()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_get_collection.html
    pub fn getCollection(self: Client, db: []const u8, collection: []const u8) Collection {
        const col = c.mongoc_client_get_collection(self.client, @ptrCast(db), @ptrCast(collection));

        return Collection{
            .collection = col,
        };
    }

    /// Get a newly allocated mongoc_database_t for the database named name.
    /// A newly allocated mongoc_database_t that should be freed with mongoc_database_destroy() when no longer in use.
    ///
    /// NOTE. Databases are automatically created on the MongoDB server upon insertion of the first document into a collection.
    /// There is no need to create a database manually.
    ///
    /// - client: A mongoc_client_t.
    /// - name: The name of the database.
    ///
    /// mongoc_client_get_database()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_get_database.html
    pub fn getDatabase(self: Client, name: []const u8) Database {
        const db = c.mongoc_client_get_database(self.client, @ptrCast(name));
        return Database{
            .database = db,
        };
    }

    /// Get the database named in the MongoDB connection URI, or NULL if the URI specifies none.
    /// Useful when you want to choose which database to use based only on the URI in a configuration file.
    /// E.g.
    /// - client with URI: `"mongodb://host/db_name"` -> default database is `db_name`
    /// - client with URI: `"mongodb://host/"` -> no default database.
    ///
    /// See example: https://mongoc.org/libmongoc/current/mongoc_client_get_default_database.html#example
    ///
    /// It returns a newly allocated mongoc_database_t that should be freed with mongoc_database_destroy().
    ///
    /// mongoc_client_get_default_database()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_get_default_database.html
    pub fn getDefaultDatabase(self: Client) Database {
        const db = c.mongoc_client_get_default_database(self.client);
        return Database{
            .database = db,
        };
    }

    /// This is a simplified interface to mongoc_client_command().
    /// It returns the first document from the result cursor into reply.
    /// The client’s read preference, read concern, and write concern are not applied to the command.
    ///
    /// NOTE. reply is always set, and should be released with bson_destroy().
    /// This function is not considered a retryable read operation.
    ///
    /// - client: A mongoc_client_t.
    /// - db_name: The name of the database to run the command on.
    /// - command: A bson_t containing the command specification.
    /// - read_prefs: An optional mongoc_read_prefs_t. Otherwise, the command uses mode MONGOC_READ_PRIMARY.
    /// - reply: A maybe-NULL pointer to overwritable storage for a bson_t to contain the results.
    /// - error: An optional location for a bson_error_t or NULL.
    ///
    /// Returns true if successful. Returns false and sets error if there are invalid arguments or a server or network error.
    /// This function does not check the server response for a write concern error or write concern timeout.
    ///
    /// mongoc_client_command_simple()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_client_command_simple.html
    pub fn commandSimple(self: Client, db_name: []const u8, command: *const Bson, read_prefs: ReadPrefs, reply: *Bson, err: *BsonError) bool {
        return c.mongoc_client_command_simple(self.client, @ptrCast(db_name), command.ptrConst(), read_prefs.ptrOrNull(), reply.ptr(), err.ptr());
    }

    // ping connects to the server and do the hand shake.
    // It returns true if successful otherwise, false.
    pub fn ping(self: Client) bool {
        var command = Bson.new();
        defer command.destroy();
        var reply = Bson.new();
        defer reply.destroy();

        command.appendInt32("ping", 1) catch |err| {
            std.debug.print("appendInt32() failed: {any}\n", .{err});
            return false;
        };

        const read_prefs = ReadPrefs.init();
        defer read_prefs.destroy();

        var err1 = BsonError.init();

        const ok = self.commandSimple("fakedb", &command, read_prefs, &reply, &err1);
        if (!ok) {
            std.debug.print("ping failed: {any}\n", .{err1.string()});
            return false;
        }

        return ok;
    }

    // mongoc_client_command()
    // mongoc_client_command_simple_with_server_id()
    // mongoc_client_command_with_opts()
    // mongoc_client_destroy()
    // mongoc_client_enable_auto_encryption()
    // mongoc_client_find_databases_with_opts()
    // mongoc_client_get_crypt_shared_version()
    // mongoc_client_get_database_names_with_opts()
    // mongoc_client_get_gridfs()
    // mongoc_client_get_handshake_description()
    // mongoc_client_get_read_concern()
    // mongoc_client_get_read_prefs()
    // mongoc_client_get_server_description()
    // mongoc_client_get_server_descriptions()
    // mongoc_client_get_uri()
    // mongoc_client_get_write_concern()
    // mongoc_client_read_command_with_opts()
    // mongoc_client_read_write_command_with_opts()
    // mongoc_client_reset()
    // mongoc_client_select_server()
    // mongoc_client_set_apm_callbacks()
    // mongoc_client_set_error_api()
    // mongoc_client_set_read_concern()
    // mongoc_client_set_read_prefs()
    // mongoc_client_set_server_api()
    // mongoc_client_set_ssl_opts()
    // mongoc_client_set_stream_initiator()
    // mongoc_client_set_write_concern()
    // mongoc_client_start_session()
    // mongoc_client_watch()
    // mongoc_client_write_command_with_opts()
    // mongoc_handshake_data_append()

    // mongoc_client_get_database_names() - Depreciated DO  NOT USE
};
