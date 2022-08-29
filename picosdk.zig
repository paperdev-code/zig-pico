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
    board: pico.Board,
    libs: []const Library,
) *PicoAppStep {
    return pico.PicoAppStep.create(
        builder,
        name,
        root_src,
        board,
        libs,
    );
}

// I want wrappers and packages, so this will likely change
pub usingnamespace struct {
    pub const pico_stdlib = Library {
        .name = "pico_stdlib",
    };

    pub const pico_cyw43_arch_none = Library {
        .name = "pico_cyw43_arch_none",
    };
};

