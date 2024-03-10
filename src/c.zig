pub const lib = @cImport({
    @cInclude("mongoc.h");
    @cInclude("bson.h");
    // @cInclude("/mnt/projects/zmongo/c/include/mongoc/mongoc.h");
    // @cInclude("/mnt/projects/zmongo/c/include/bson/bson.h");
});
