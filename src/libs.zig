const std = @import("std");
const util = @import("util.zig");
const cmake = @import("cmake.zig");

const Builder = std.build.Builder;
const Step = std.build.Step;

pub const libraries = struct {
    pub const pico_stdlib = Library {
        .name = "pico_stdlib",
        .path = "todo",
    };

    pub const pico_cyw43_arch_none = Library {
        .name = "pico_cyw43_arch_none",
        .path = "todo",
    };
};

pub const Library = struct {
    name: []const u8,
    path: []const u8,

    /// Actual library linking is handled by the Pico SDK,
    /// so dependencies are not handled here.
    pub fn listNames(
        allocator: std.mem.Allocator,
        libs: []const Library
    ) ![]const u8 {
        var list = std.ArrayList(u8).init(allocator);
        for (libs) |lib| {
            try list.appendSlice(lib.name);
            try list.append(' ');
        }
        return list.toOwnedSlice();
    }
};

