cmake_minimum_required(VERSION 3.9)

set(CMAKE_C_STANDARD 11)

set(PICO_BOARD "pico_w")

include(pico_sdk_import.cmake)

project(zig-pico)

pico_sdk_init()

set(ZIG_APP_PATH ${CMAKE_CURRENT_BINARY_DIR}/libmain.a)

add_library(zig-app STATIC IMPORTED GLOBAL)
set_target_properties(zig-app
    PROPERTIES
    IMPORTED_LOCATION ${ZIG_APP_PATH}
)

add_executable(zig-pico
    src/entry.c
)

target_link_libraries(zig-pico
    zig-app
    pico_stdlib
    pico_cyw43_arch_none
)

pico_enable_stdio_usb(zig-pico 1)
pico_enable_stdio_uart(zig-pico 0)

pico_add_extra_outputs(zig-pico)
