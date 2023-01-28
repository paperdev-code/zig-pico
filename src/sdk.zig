const std = @import("std");
const util = @import("util.zig");
const Library = @import("Library.zig");

const Builder = std.build.Builder;
const Step = std.build.Step;
const LibExeObjStep = std.build.LibExeObjStep;
const ArrayList = std.ArrayList;

pub const GenPicoListsStep = struct {
    const Self = @This();

    const entry_c = "entry.c";
    const cmake_version = "3.9";
    const c_std = "11";
    const cxx_std = "17";

    builder: *Builder,
    step: Step,
    txt: ?[]const u8,
    app: *LibExeObjStep,
    libs: *ArrayList(Library),
    // pio_files: *ArrayList([]const u8),
    board: []const u8,
    enable_stdio: Stdio_Options,

    pub fn create(
        builder: *Builder,
        app: *LibExeObjStep,
        board: []const u8,
        libs: *ArrayList(Library),
        // pio_files: *ArrayList([]const u8),
    ) *Self {
        const self = builder.allocator.create(Self) catch unreachable;
        self.* = Self {
            .builder = builder,
            .step = Step.init(
                .custom,
                "genpicolists-step",
                builder.allocator,
                make,
            ),
            .txt = null,
            .app = app,
            .libs = libs,
            // .pio_files = pio_files,
            .board = board,
            .enable_stdio = .none,
        };
        return self;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(Self, "step", step);
        const allocator = self.builder.allocator;

        var txt = std.ArrayList(u8).init(allocator);
        const writer = txt.writer();

        const pico_sdk_import = try includePicoSdk(allocator);
        defer allocator.free(pico_sdk_import);

        const entry_c_path = try std.mem.concat(allocator, u8, &.{
            util.picoZigDirPath(),
            std.fs.path.sep_str,
            entry_c,
        });
        defer allocator.free(entry_c_path);

        const real_prefix_path = try util.zigInstallDirPath(self.builder);
        defer allocator.free(real_prefix_path);

        const app_path = try std.mem.concat(allocator, u8 , &.{
            real_prefix_path,
            std.fs.path.sep_str,
            self.app.override_dest_dir.?.custom,
            std.fs.path.sep_str,
            "lib",
            self.app.name,
            ".a",
        });
        defer allocator.free(app_path);

        const libnames = try Library.listNames(allocator, self.libs.items);
        defer allocator.free(libnames);

        const usb : i32 =
            if (self.enable_stdio == .usb or self.enable_stdio == .uart_usb) 1 else 0;
        const uart : i32 =
            if (self.enable_stdio == .uart or self.enable_stdio == .uart_usb) 1 else 0;

        // var pio_paths = ArrayList(u8).init(allocator);
        // defer pio_paths.deinit();
        // var pio_writer = pio_paths.writer();
        // for (self.pio_files.items) |pio| {
        //    const pio_path = try std.mem.concat(allocator, u8, &.{
        //        self.builder.build_root,
        //        std.fs.path.sep_str,
        //        pio,
        //    });
        //    defer allocator.free(pio_path);
        //    try pio_writer.print("pico_generate_pio_header({s} {s})", .{
        //        self.app.name, pio_path,
        //    });
        // }

        try writer.print(
            \\cmake_minimum_required(VERSION {s})
            \\set(PICO_BOARD "{s}")
            \\set(CMAKE_C_STANDARD {s})
            \\set(CMAKE_CXX_STANDARD {s})
            \\#include(pico_sdk_import.cmake)
            \\{s}
            \\project({s})
            \\pico_sdk_init()
            \\add_library(zig-app-lib STATIC IMPORTED GLOBAL)
            \\set_target_properties(zig-app-lib PROPERTIES IMPORTED_LOCATION {s})
            \\add_executable({s} {s})
            \\target_link_libraries({s} zig-app-lib {s})
            \\pico_enable_stdio_usb({s} {d})
            \\pico_enable_stdio_uart({s} {d})
            \\pico_add_extra_outputs({s})
            ,
            .{
                cmake_version,
                self.board,
                c_std,
                cxx_std,
                pico_sdk_import,
                self.app.name,
                app_path,
                self.app.name, entry_c_path,
                // pio_paths.items,
                self.app.name, libnames,
                self.app.name, usb,
                self.app.name, uart,
                self.app.name,
            }
        );

        self.txt = txt.toOwnedSlice();
    }

    fn includePicoSdk(allocator: std.mem.Allocator) ![]const u8 {
        if (util.picoSdkDirPath()) |pico_sdk_path| { 
            var pico_sdk_dir = try std.fs.openDirAbsolute(pico_sdk_path, .{});
            defer pico_sdk_dir.close();
            var pico_sdk_import = try pico_sdk_dir.openFile(
                "external" ++ std.fs.path.sep_str ++ "pico_sdk_import.cmake", .{}
            );
            defer pico_sdk_import.close();
            var contents = std.ArrayList(u8).init(allocator);
            var reader = pico_sdk_import.reader();
            try reader.readAllArrayList(&contents, 5000);
            return contents.toOwnedSlice();
        }
        else |err| return err;
    }
};

pub const Stdio_Options = enum {
    none,
    uart,
    usb,
    uart_usb
};

