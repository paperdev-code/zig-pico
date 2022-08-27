const std = @import("std");
const pico = @import("src/pico.zig");
const sdk = @import("src/sdk.zig");

const Builder = std.build.Builder;
const PicoAppStep = pico.PicoAppStep;
const Library = sdk.Library;

pub fn addPicoApp(
    builder: *Builder,
    name: []const u8,
    root_src: []const u8,
    comptime board: @Type(.EnumLiteral),
    libs: []const Library,
) *PicoAppStep {
    return pico.PicoAppStep.create(
        builder,
        name,
        root_src,
        @tagName(board),
        libs,
    );
}

pub usingnamespace sdk.libraries;
