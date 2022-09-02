const std = @import("std");
const picosdk = @import("picosdk.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const board = .{ .pico_w = .{ .cyw43_arch = .threadsafe_background } };

    const pico_app = picosdk.addPicoApp(
        b,
        "pico-app",
        "example/main.zig",
        board,
    );

    pico_app.addLibraries(&.{
        picosdk.pico_stdlib,
        picosdk.pico_cyw43_arch_none,
        picosdk.hardware_pio,
    });

    pico_app.addPioSources(&.{
        "example/blink.pio",
    });

    pico_app.zig.setBuildMode(mode);
    pico_app.enable_stdio(.usb);
    pico_app.install();
}

