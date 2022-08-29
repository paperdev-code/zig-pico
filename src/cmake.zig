const std = @import("std");
const util = @import("util.zig");

const Builder = std.build.Builder;
const Step = std.build.Step;
const Dir = std.fs.Dir;
const File = std.fs.File;
const InstallArtifactStep = std.build.InstallArtifactStep;
const LibExeObjStep = std.build.LibExeObjStep;

pub const MakeStep = struct {
    const Self = @This();

    builder: *Builder,
    step: Step,
    build_dir: ?[]const u8,
    cmakebuild: *BuildStep,

    pub fn create(
        builder: *Builder,
        cmakebuild: *BuildStep,
    ) *Self {
        const self = builder.allocator.create(Self) catch unreachable;
        self.* = Self {
            .builder = builder,
            .step = Step.init(
                .custom,
                "cmakemake-step",
                builder.allocator,
                make,
            ),
            .build_dir = null,
            .cmakebuild = cmakebuild,
        };
        self.step.dependOn(&cmakebuild.step);
        return self;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(Self, "step", step);
        if (self.cmakebuild.build_dir) |cwd| {
            self.build_dir = cwd;
            try util.exec(
                self.builder.allocator,
                &.{"make"},
                cwd,
                .CmakeMake
            );
        }
        else return error.CmakeBuildDirNull;
 
    }
};

pub const BuildStep = struct {
    const Self = @This();

    builder: *Builder,
    step: Step,
    build_dir: ?[]const u8,
    cmakelists: *ListsStep,

    pub fn create(
        builder: *Builder,
        cmakelists: *ListsStep,
        zig: *LibExeObjStep,
    ) *Self {
        const self = builder.allocator.create(Self) catch unreachable;
        self.* = Self {
            .builder = builder,
            .step = Step.init(
                .custom,
                "cmakebuild-step",
                builder.allocator,
                make,
            ),
            .build_dir = null,
            .cmakelists = cmakelists,
        };
        self.step.dependOn(&cmakelists.step);
        //self.step.dependOn(zig.install_step.?.step);
        zig.step.dependOn(&self.step);
        return self;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(Self, "step", step);
        if (self.cmakelists.path) |path| {
            self.build_dir = self.cmakelists.build_dir.?;
            try util.exec(
                self.builder.allocator,
                &.{"cmake", "-S", path, "-B", self.build_dir.?},
                null,
                .CmakeBuild
            );
        }
        else return error.CmakeListsPathNull;
    }
};

pub const ListsStep = struct {
    const Self = @This();

    const dir_name = "cmake";
    const build_dir_name = "build";
    const txt_name = "CMakeLists.txt";

    builder: *Builder,
    step: Step,
    txt: ?[]const u8,
    txt_src: ?*?[]const u8,
    path: ?[]const u8,
    build_dir: ?[]const u8,

    pub fn create(
        builder: *Builder,
    ) *Self {
        const self = builder.allocator.create(Self) catch unreachable;
        self.* = Self {
            .builder = builder,
            .step = Step.init(
                .custom,
                "cmakelists-step",
                builder.allocator,
                make,
            ),
            .txt = null,
            .txt_src = null,
            .path = null,
            .build_dir = null,
        };
        return self;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(Self, "step", step);

        const cmakelists_txt_contents =
            if (self.txt) |txt| txt
            else if (self.txt_src) |src| src.*
            else null;

        if (cmakelists_txt_contents) |txt| {
            var cmake_dir = try util.zigCacheMakeOpenPath(
                self.builder,
                dir_name,
                .{},
                .CmakeLists
            );
            defer cmake_dir.close();
            var cmakelists_txt = try cmake_dir.createFile(txt_name, .{});
            try cmakelists_txt.writeAll(txt);
            std.log.scoped(.CMakeLists).info("Written CMakeLists.txt", .{});

            self.build_dir = try util.zigCacheMakePath(
                self.builder,
                build_dir_name,
                .CmakeLists,
            );

            self.path = try std.mem.concat(self.builder.allocator, u8, &.{
                self.builder.build_root,
                std.fs.path.sep_str,
                self.builder.cache_root,
                std.fs.path.sep_str,
                dir_name,
                // std.fs.path.sep_str,
                // txt_name,
            });
        }
        else return error.TxtContentsNull;
    }
};

