const std = @import("std");
const sdk = @import("sdk.zig");
const cmake = @import("cmake.zig");
const util = @import("util.zig");
const Library = @import("Library.zig");

const Builder = std.build.Builder;
const Step = std.build.Step;
const LibExeObjStep = std.build.LibExeObjStep;
const CreateOptions = std.build.InstallRawStep.CreateOptions;
const ArrayList = std.ArrayList;

pub const Board = union(enum) {
    pico: void,
    pico_w: struct {
        cyw43_arch: enum {
            threadsafe_background,
            poll,
        },
    },
};

pub const rp2040_target = std.zig.CrossTarget {
    .cpu_arch = .thumb,
    .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    .os_tag = .freestanding,
    .abi = .eabi,
};

pub const PicoAppStep = struct {
    const Self = @This();

    builder: *Builder,
    step: Step,
    zig: *LibExeObjStep,
    pio_files: ArrayList([]const u8),
    board: Board,
    libs: ArrayList(Library),
    genpicolists: *sdk.GenPicoListsStep,
    cmakemake: *cmake.MakeStep,
    emit_uf2: bool,

    pub fn create(
        builder: *Builder,
        name: []const u8,
        root_src: ?[]const u8,
        board: Board,
    ) *Self {
        const self = builder.allocator.create(Self) catch unreachable;
        self.* = Self {
            .builder = builder,
            .step = Step.init(
                .custom,
                "picoapp-step",
                builder.allocator,
                make,
            ),
            .zig = builder.addStaticLibrary(name, root_src),
            .pio_files = ArrayList([]const u8).init(builder.allocator),
            .libs = ArrayList(Library).init(builder.allocator),
            .board = board,
            .emit_uf2 = true,
            .genpicolists = undefined,
            .cmakemake = undefined,
        };

        self.zig.setTarget(rp2040_target);
        self.zig.override_dest_dir = std.build.InstallDir {
            .custom = "lib",
        };
        self.zig.install();

        const genpicolists = sdk.GenPicoListsStep.create(
            self.builder,
            self.zig,
            @tagName(board),
            &self.libs,
            &self.pio_files,
        );

        const cmakelists = cmake.ListsStep.create(builder);
        cmakelists.txt_src = &genpicolists.txt;
        cmakelists.step.dependOn(&genpicolists.step);

        const cmakebuild = cmake.BuildStep.create(
            self.builder,
            cmakelists,
            self.zig,
        );

        const cmakemake = cmake.MakeStep.create(builder, cmakebuild);
        cmakemake.step.dependOn(&self.zig.install_step.?.step);

        _ = Library.IncludeStep.create(
            self.builder,
            self.zig,
            cmakelists,
            self.board,
        );

        self.genpicolists = genpicolists;
        self.cmakemake = cmakemake;
        self.step.dependOn(&cmakemake.step);
        return self;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(Self, "step", step);
        var build_dir = try std.fs.openDirAbsolute(self.cmakemake.build_dir.?, .{});
        defer build_dir.close();
        if (self.emit_uf2) {
            const uf2_name = try std.mem.concat(self.builder.allocator, u8, &.{
                self.zig.name, ".uf2"
            });
            defer self.builder.allocator.free(uf2_name);
            var uf2_dir = try util.zigBuildMakeOpenPath(
                self.builder,
                "uf2",
                .{},
                .PicoApp
            );
            defer uf2_dir.close();
            try build_dir.copyFile(uf2_name, uf2_dir, uf2_name, .{});
        }
    }

    pub fn addLibraries(self: *Self, libs: []const Library) void {
        self.libs.appendSlice(libs) catch unreachable;
    }

    pub fn addPioSources(self: *Self, pio_files: []const []const u8) void {
        self.pio_files.appendSlice(pio_files) catch unreachable;
    }

    pub fn enable_stdio(self: *Self, stdio: sdk.Stdio_Options) void {
        self.genpicolists.enable_stdio = stdio;
    }

    pub fn install(self: *Self) void {
        self.builder.getInstallStep().dependOn(&self.step);
    }
}; 
