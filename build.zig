const std = @import("std");

const cmake_build_path = "./build";

pub fn build(b: *std.build.Builder) void {
    const target = std.zig.CrossTarget {
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
        .os_tag = .freestanding,
        .abi = .eabi,
    };
    const mode = b.standardReleaseOptions();

    const build_path = std.mem.concat(b.allocator, u8, &.{
        b.build_root,
        std.fs.path.sep_str,
        cmake_build_path,
    }) catch unreachable;

    const zig_main = b.addStaticLibrary("main", "./src/main.zig");
    zig_main.setTarget(target);
    zig_main.setBuildMode(mode);
    zig_main.override_dest_dir = std.build.InstallDir {.custom = "."};
    zig_main.install();

    // should make this part of an 'init' step?
    const build_root = std.fs.openDirAbsolute(b.build_root, .{}) catch unreachable;
    build_root.makePath(cmake_build_path) catch unreachable;

    const cmake_cmd = b.addSystemCommand(&.{
        "cmake", ".."
    });
    cmake_cmd.cwd = build_path;
    const cmake = b.step("cmake", "create cmake build files");
    cmake.dependOn(&cmake_cmd.step);

    // this is what lack of Cmake knowledge does to a man
    const zig_build_cmd = b.addSystemCommand(&.{
        "zig",
        "build",
        "install",
        "--prefix",
        build_path,
    });

    const make_cmd = b.addSystemCommand(&.{
        "make"
    });
    make_cmd.cwd = build_path;
    make_cmd.step.dependOn(&zig_build_cmd.step);

    const firmware = b.step("firmware", "build the pico uf2 file");
    firmware.dependOn(&make_cmd.step);
}

