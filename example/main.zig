const std = @import("std");

const c = @cImport({
    @cInclude("pico/stdlib.h");
    @cInclude("pico/stdio.h");
    @cInclude("pico/cyw43_arch.h");
});

const CYW43_WL_GPIO_LED_PIN = 0;

var led_state : bool = false;
var total_blinks : i32 = 0;

export fn init() void {
    c.stdio_init_all();
    if (c.cyw43_arch_init() != 1) {
        std.log.info("WiFi fail.", .{});
        return;
    }
}

export fn loop() void {
    led_state = !led_state;
    c.cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, led_state);
    c.sleep_ms(350);

    if (led_state == false) {
        std.log.info("Blink! {d}", .{total_blinks});
        total_blinks = total_blinks + 1;
    }
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    var buffer: [1024]u8 = .{};
    var message = std.fmt.bufPrint(&buffer, level_txt ++ prefix2 ++ format ++ "\n\r", args) catch return;
    for (message) |char| {
        _ = c.putchar_raw(char);
    }
}

