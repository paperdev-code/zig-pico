const std = @import("std");
const pico = @import("src/pico.zig");
const sdk = @import("src/sdk.zig");
const Library = @import("src/Library.zig");

const Builder = std.build.Builder;
const PicoAppStep = pico.PicoAppStep;

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

pub usingnamespace struct {
    pub const pico_stdlib = Library {
        .name = "pico_stdlib",
        .path = "todo",
    };

    pub const pico_cyw43_arch_none = Library {
        .name = "pico_cyw43_arch_none",
        .path = "todo",
    };
};

