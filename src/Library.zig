const std = @import("std");
const util = @import("util.zig");
const cmake = @import("cmake.zig");
const pico = @import("pico.zig");

const Self = @This();

const Builder = std.build.Builder;
const Step = std.build.Step;
const LibExeObjStep = std.build.LibExeObjStep;
const ArrayList = std.ArrayList;

name: []const u8,

/// Actual library linking is handled by the Pico SDK,
/// so dependencies are not handled here.
pub fn listNames(
    allocator: std.mem.Allocator,
    libs: []const Self,
) ![]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    for (libs) |lib| {
        try list.appendSlice(lib.name);
        try list.append(' ');
    }
    return list.toOwnedSlice();
}

/// find... all SDK include dirs :P
fn allSdkIncludeDirs(allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
    const pico_sdk_path = try util.picoSdkDirPath();
    const pico_sdk_path_src = try std.mem.concat(allocator, u8, &.{
        pico_sdk_path,
        std.fs.path.sep_str,
        "src",
    });
    defer allocator.free(pico_sdk_path_src);
    var dirs = ArrayList([]const u8).init(allocator);
    var pico_sdk = try std.fs.openIterableDirAbsolute(pico_sdk_path_src, .{});
    defer pico_sdk.close();
    var walker = try pico_sdk.walk(allocator);
    while (try walker.next()) |entry| {
        if (entry.kind == .Directory) {
            if (std.mem.eql(u8, entry.basename, "include")) {
                const full_path = try std.mem.concat(allocator, u8, &.{
                    pico_sdk_path_src,
                    std.fs.path.sep_str,
                    entry.path
                });
                try dirs.append(full_path);
            }
        }
    }
    // some left overs.
    // but just scanning for anything containing a .h seems too much
    for ([_][]const u8 {
        "lib/cyw43-driver/src",
        "lib/tinyusb/src",
        "lib/lwip/src/include",
        "test/kitchen_sink",
    }) |path| {
        const absolute_path = try std.mem.concat(allocator, u8, &.{
            pico_sdk_path,
            std.fs.path.sep_str,
            path,
        });
        try dirs.append(absolute_path);
    }

    return dirs;
}

pub const IncludeStep = struct {

    builder: *Builder,
    step: Step,
    zig: *LibExeObjStep,
    cmakelists: *cmake.ListsStep,
    board: pico.Board,

    pub fn create(
        builder: *Builder,
        zig: *LibExeObjStep,
        cmakelists: *cmake.ListsStep,
        board: pico.Board,
    ) *IncludeStep {
        const self = builder.allocator.create(IncludeStep) catch unreachable;
        self.* = IncludeStep {
            .builder = builder,
            .step = Step.init(
                .custom,
                "libraryinclude-step",
                builder.allocator,
                make,
            ),
            .zig = zig,
            .cmakelists = cmakelists,
            .board = board,
        };
        self.zig.linkLibC();
        self.step.dependOn(&self.cmakelists.step);
        self.zig.step.dependOn(&self.step);
        return self;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(IncludeStep, "step", step);
        const allocator = self.builder.allocator;
        const include_paths = try allSdkIncludeDirs(allocator);
        defer include_paths.deinit();
        // pico sdk include paths
        for (include_paths.items) |include_path| {
            std.log.scoped(.cInclude).info("{s}", .{include_path});
            self.zig.addIncludeDir(include_path);
        }
        // pico generated
        const generated = try std.mem.concat(allocator, u8, &.{
            self.cmakelists.build_dir.?,
            std.fs.path.sep_str,
            "generated",
            std.fs.path.sep_str,
            "pico_base",
        });
        defer allocator.free(generated);
        self.zig.addSystemIncludeDir(generated);
        self.zig.addIncludeDir(self.cmakelists.build_dir.?);
        self.zig.addSystemIncludeDir("/usr/lib/arm-none-eabi/include");

        switch (self.board) {
            .pico_w => |config| {
                switch (config.cyw43_arch) {
                    .threadsafe_background => {
                        self.zig.defineCMacro(
                            "PICO_CYW43_ARCH_THREADSAFE_BACKGROUND",
                            null,
                        );
                    },
                    .poll => {
                        self.zig.defineCMacro(
                            "PICO_CYW43_ARCH_POLL",
                            null
                        );
                    },
                }
            },
            .pico => |_| {},
        }
    }
};

