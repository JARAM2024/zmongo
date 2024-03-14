const c = @import("c.zig").lib;

pub const Database = struct {
    ptr: *c.mongoc_database_t,

    // Ref. https://mongoc.org/libmongoc/current/mongoc_database_t.html
    // mongoc_database_add_user()
    // mongoc_database_aggregate()
    // mongoc_database_command()
    // mongoc_database_command_simple()
    // mongoc_database_command_with_opts()
    // mongoc_database_copy()
    // mongoc_database_create_collection()
    // mongoc_database_destroy()
    // mongoc_database_drop()
    // mongoc_database_drop_with_opts()
    // mongoc_database_find_collections()
    // mongoc_database_find_collections_with_opts()
    // mongoc_database_get_collection()
    // mongoc_database_get_collection_names()
    // mongoc_database_get_collection_names_with_opts()
    // mongoc_database_get_name()
    // mongoc_database_get_read_concern()
    // mongoc_database_get_read_prefs()
    // mongoc_database_get_write_concern()
    // mongoc_database_has_collection()
    // mongoc_database_read_command_with_opts()
    // mongoc_database_read_write_command_with_opts()
    // mongoc_database_remove_all_users()
    // mongoc_database_remove_user()
    // mongoc_database_set_read_concern()
    // mongoc_database_set_read_prefs()
    // mongoc_database_set_write_concern()
    // mongoc_database_watch()
    // mongoc_database_write_command_with_opts()

};
