# Zig on the Pico W
Zig on the Raspberry Pi Pico W without losing access to the SDK.

# Requirements
Have the Pico SDK set up like normal.

# Build
```shell
# create build directory
zig build cmake

# build the firmware
zig build firmware
```

# Todo
- [ ] integrate CMakeLists.txt into zig build somehow
- [ ] configure pico-sdk components through zig build
- [ ] ???
- [ ] profit

Use the produced UF2 file on your Pico.

### Warning
This is incredibly scuffed, the zig build script literally calls itself.

