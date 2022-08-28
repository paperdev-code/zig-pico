const std = @import("std");
const sdk = @import("sdk.zig");
const cmake = @import("cmake.zig");
const util = @import("util.zig");
const Library = @import("Library.zig");

const Builder = std.build.Builder;
const Step = std.build.Step;
const LibExeObjStep = std.build.LibExeObjStep;
const CreateOptions = std.build.InstallRawStep.CreateOptions;

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
    genpicolists: *sdk.GenPicoListsStep,
    cmakelists: *cmake.ListsStep,
    cmakebuild: *cmake.BuildStep,
    cmakemake: *cmake.MakeStep,
    emit_uf2: bool,

    pub fn create(
        builder: *Builder,
        name: []const u8,
        root_src: ?[]const u8,
        board: []const u8,
        libs: []const Library,
    ) *Self {
        const self = builder.allocator.create(Self) catch unreachable;
        const zig = builder.addStaticLibrary(name, root_src);
        zig.setTarget(rp2040_target);
        zig.override_dest_dir = std.build.InstallDir {
            .custom = "lib",
        }; 
        zig.install();
        //zig.linkLibC();
        //const include_paths = libs.Library.listIncludes(
        //    builder.allocator,
        //    libs,
        //) catch unreachable;
        //defer include_paths.deinit();
        //for (include_paths.items) |include_path| {
        //    zig.addIncludePath(include_path);
        //    std.debug.print("{s}\n", .{include_path});
        //}
        const genpicolists = sdk.GenPicoListsStep.create(
            builder,
            zig,
            board,
            libs,
        );
        const cmakelists = cmake.ListsStep.create(builder);
        cmakelists.txt_src = &genpicolists.txt;
        cmakelists.step.dependOn(&genpicolists.step);
        const cmakebuild = cmake.BuildStep.create(builder, cmakelists);
        const cmakemake = cmake.MakeStep.create(builder, cmakebuild);
        self.* = Self {
            .builder = builder,
            .step = Step.init(
                .custom,
                "picoapp-step",
                builder.allocator,
                make,
            ),
            .zig = zig,
            .genpicolists = genpicolists,
            .cmakelists = cmakelists,
            .cmakebuild = cmakebuild,
            .cmakemake = cmakemake,
            .emit_uf2 = true,
        };
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

    pub fn enable_stdio(self: *Self, stdio: sdk.Stdio_Options) void {
        self.genpicolists.enable_stdio = stdio;
    }

    pub fn install(self: *Self) void {
        self.builder.getInstallStep().dependOn(&self.step);
    }
}; 
