const std = @import("std");
const c = @import("c.zig").lib;
const bson = @import("bson.zig");
const mongo = @import("mongo.zig");

pub const Host = struct {
    host_list: c.mongoc_host_list_t,

    pub fn init() Host {
        return Host{
            .host_list = undefined,
        };
    }

    pub fn ptr(self: Host) *c.mongoc_host_list_t {
        return &self.host_list;
    }

    // TODO. APIs to iterate list of host.
    // Mongoc does not provide any APIs to iterate.
};
