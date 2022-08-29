const std = @import("std");

/// Path to this src dir, required for 'entry.c'
pub fn picoZigDirPath() []const u8 {
    return std.fs.path.dirname(@src().file) orelse unreachable;
}

pub fn picoSdkDirPath() ![]const u8 {
    return std.os.getenv("PICO_SDK_PATH") orelse error.PicoSdkPathEnv;
}

/// allocs with builder
pub fn zigInstallDirPath(b : *std.build.Builder) ![]const u8 {
    var path_buffer : [std.fs.MAX_PATH_BYTES]u8 = .{};
    if (std.fs.path.isAbsolute(b.install_prefix)) {
        return try b.allocator.dupe(u8, b.install_prefix);
    }
    else {
        const parent_dir = try std.fs.realpath(
            ".",
            &path_buffer
        );
        return try std.mem.concat(b.allocator, u8, &.{
            parent_dir,
            std.fs.path.sep_str,
            b.install_prefix,
        });
    }
}

/// Like std.ChildProcess.exec but with failure based on process exit state
pub fn exec(
    allocator: std.mem.Allocator,
    argv: []const []const u8,
    cwd: ?[]const u8,
    comptime log_scope: anytype,
) !void {
    const command = try std.mem.concat(allocator, u8, argv);
    defer allocator.free(command);

    std.log.scoped(log_scope).info("{s} $ {s}", .{cwd orelse "", command});

    const result = try std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = cwd,
    });
    
    std.log.scoped(log_scope).info("{s}\n{s}", .{result.stderr, result.stdout});

    switch (result.term) {
        .Exited => |code| {
           if (code != 0) return error.ProcessFailed;
        },
        else => return error.ProcessUnhandled,
    }
}

pub fn zigCacheMakePath(
    b: *std.build.Builder,
    sub_path: []const u8,
    comptime log_scope: anytype,
) ![]const u8 {
    const actual_cache_root = b.pathFromRoot(b.cache_root);
    defer b.allocator.free(actual_cache_root);
    var cache_dir = try std.fs.openDirAbsolute(actual_cache_root, .{});
    defer cache_dir.close();
    try cache_dir.makePath(sub_path);
    std.log.scoped(log_scope).debug("made path {s}{s}{s}", .{
        actual_cache_root,
        std.fs.path.sep_str,
        sub_path,
    });
    return std.mem.concat(b.allocator, u8, &.{
        actual_cache_root,
        std.fs.path.sep_str,
        sub_path,
    });
}

/// Ensure path exists inside zig-cache and open it.
pub fn zigCacheMakeOpenPath(
    b: *std.build.Builder,
    sub_path: []const u8,
    flags: std.fs.Dir.OpenDirOptions,
    comptime log_scope: anytype,
) !std.fs.Dir {
    const actual_cache_root = b.pathFromRoot(b.cache_root);
    defer b.allocator.free(actual_cache_root);
    var cache_dir = try std.fs.openDirAbsolute(actual_cache_root, .{});
    defer cache_dir.close();
    const dir = try cache_dir.makeOpenPath(sub_path, flags);
    std.log.scoped(log_scope).debug("opened path {s}{s}{s}", .{
        actual_cache_root,
        std.fs.path.sep_str,
        sub_path,
    });
    return dir;
}

pub fn zigBuildMakeOpenPath(
    b: *std.build.Builder,
    sub_path: []const u8,
    flags: std.fs.Dir.OpenDirOptions,
    comptime log_scope: anytype,
) !std.fs.Dir {
    const real_prefix_path = try zigInstallDirPath(b);
    defer b.allocator.free(real_prefix_path);
    var build_dir = try std.fs.openDirAbsolute(real_prefix_path, .{});
    defer build_dir.close();
    const dir = try build_dir.makeOpenPath(sub_path, flags);
    std.log.scoped(log_scope).debug("opened path {s}{s}{s}", .{
        b.install_path,
        std.fs.path.sep_str,
        sub_path,
    });
    return dir;
}
