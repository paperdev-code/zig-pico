extern fn stdio_init_all() void;
extern fn cyw43_arch_gpio_put(pin : c_int, value : c_int) void;
extern fn sleep_ms(ms : c_int) void;

const CYW43_WL_GPIO_LED_PIN = 0;

var b : i32 = 0;

export fn zigMain() void {
    while (true) {
        b = if (b == 0) 1 else 0;
        cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, b);
        sleep_ms(250);
    }
}

