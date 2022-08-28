const std = @import("std");
const pico = @import("src/pico.zig");
const sdk = @import("src/sdk.zig");
const libs = @import("src/libs.zig");

const Builder = std.build.Builder;
const PicoAppStep = pico.PicoAppStep;
const Library = libs.Library;

pub fn addPicoApp(
    builder: *Builder,
    name: []const u8,
    root_src: []const u8,
    comptime board: @Type(.EnumLiteral),
    libraries: []const Library,
) *PicoAppStep {
    return pico.PicoAppStep.create(
        builder,
        name,
        root_src,
        @tagName(board),
        libraries,
    );
}

pub usingnamespace libs.libraries;
