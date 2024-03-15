const std = @import("std");
const c = @import("c.zig").lib;
const bson = @import("bson.zig");
const mongo = @import("mongo.zig");

const Error = mongo.Error;

/// Uri provides an abstraction on top of the MongoDB connection URI format.
/// It provides standardized parsing as well as convenience methods for extracting useful
/// information such as replica hosts or authorization information.
///
/// mongodb[+srv]://                              <1>
///     [username:password@]                      <2>
///     host1                                     <3>
///     [:port1]                                  <4>
///     [,host2[:port2],...[,hostN[:portN]]]      <5>
///     [/[database]                              <6>
///     [?options]]                               <7>
///
/// 1. “mongodb” is the specifier of the MongoDB protocol. Use “mongodb+srv” with a single service name in place
///     of “host1” to specify the initial list of servers with an SRV record.
/// 2. An optional username and password.
/// 3. The only required part of the uri. This specifies either a hostname, IPv4 address, IPv6 address
///     enclosed in “[” and “]”, or UNIX domain socket.
/// 4. An optional port number. Defaults to :27017.
/// 5. Extra optional hosts and ports. You would specify multiple hosts, for example, for connections to replica sets.
/// 6. The name of the database to authenticate if the connection string includes authentication credentials.
///     If /database is not specified and the connection string includes credentials, defaults to the ‘admin’ database.
/// 7. Connection specific options.
///
/// Ref. https://mongoc.org/libmongoc/current/mongoc_uri_t.html
pub const Uri = struct {
    ptr: ?*c.mongoc_uri_t,

    /// Parses a string containing a MongoDB style URI connection string.
    /// A newly allocated mongoc_uri_t if successful. Otherwise NULL populating error with the error description.
    ///
    /// - uri_string: A string containing a URI.
    /// - error: An optional location for a bson_error_t or NULL.
    ///
    /// mongoc_uri_new_with_error()
    /// Ref. https://mongoc.org/libmongoc/current/mongoc_uri_new_with_error.html
    pub fn new(uri_string: []const u8) !Uri {
        var err: c.bson_error_t = undefined;
        const ptr = c.mongoc_uri_new_with_error(@ptrCast(uri_string), &err);
        if (ptr != null) {
            return Uri{
                .ptr = ptr,
            };
        } else {
            std.debug.print("Uri.new() parsing URI string {s} failed: {s}\n", .{ uri_string, std.mem.sliceTo(&err.message, 0) });
            return Error.UriError;
        }
    }

    // TODO.
    // mongoc_uri_new()
    // mongoc_uri_copy()
    // mongoc_uri_destroy()
    // mongoc_uri_get_auth_mechanism()
    // mongoc_uri_get_auth_source()
    // mongoc_uri_get_compressors()
    // mongoc_uri_get_database()
    // mongoc_uri_get_hosts()
    // mongoc_uri_get_mechanism_properties()
    // mongoc_uri_get_option_as_bool()
    // mongoc_uri_get_option_as_int32()
    // mongoc_uri_get_option_as_int64()
    // mongoc_uri_get_option_as_utf8()
    // mongoc_uri_get_options()
    // mongoc_uri_get_password()
    // mongoc_uri_get_read_concern()
    // mongoc_uri_get_read_prefs()
    // mongoc_uri_get_read_prefs_t()
    // mongoc_uri_get_replica_set()
    // mongoc_uri_get_service()
    // mongoc_uri_get_ssl()
    // mongoc_uri_get_string()
    // mongoc_uri_get_srv_hostname()
    // mongoc_uri_get_srv_service_name()
    // mongoc_uri_get_tls()
    // mongoc_uri_get_username()
    // mongoc_uri_get_write_concern()
    // mongoc_uri_has_option()
    // mongoc_uri_new_for_host_port()
    // mongoc_uri_option_is_bool()
    // mongoc_uri_option_is_int32()
    // mongoc_uri_option_is_int64()
    // mongoc_uri_option_is_utf8()
    // mongoc_uri_set_auth_mechanism()
    // mongoc_uri_set_auth_source()
    // mongoc_uri_set_compressors()
    // mongoc_uri_set_database()
    // mongoc_uri_set_mechanism_properties()
    // mongoc_uri_set_option_as_bool()
    // mongoc_uri_set_option_as_int32()
    // mongoc_uri_set_option_as_int64()
    // mongoc_uri_set_option_as_utf8()
    // mongoc_uri_set_password()
    // mongoc_uri_set_read_concern()
    // mongoc_uri_set_read_prefs_t()
    // mongoc_uri_set_username()
    // mongoc_uri_set_write_concern()
    // mongoc_uri_unescape()

};
