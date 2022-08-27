const std = @import("std");
const picosdk = @import("picosdk.zig");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const pico_app = picosdk.addPicoApp(
        b,
        "pico-app",
        "example/main.zig",
        .pico_w,
        &.{
            picosdk.pico_stdlib,
            picosdk.pico_cyw43_arch_none
        },
    );

    pico_app.zig.setBuildMode(mode);
    
    pico_app.enable_stdio(.usb);

    pico_app.install();
}

