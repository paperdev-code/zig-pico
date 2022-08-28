//const c = @cImport({
//    @cInclude("pico/stdlib.h");
//    @cInclude("pico/cyw43_arch.h");
//});

extern fn stdio_init_all() void;
extern fn cyw43_arch_init() c_int;
extern fn cyw43_arch_gpio_put(pin: c_int, value: c_int) void;
extern fn sleep_ms(ms: c_int) void;

const CYW43_WL_GPIO_LED_PIN = 0;

var led_state : bool = false;

export fn init() void {
    stdio_init_all();
    if (cyw43_arch_init() != 1) {
        // adding print support after adding C includes
        return;
    }
}

export fn loop() void {
    led_state = !led_state;
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, @boolToInt(led_state));
    sleep_ms(150);
}

