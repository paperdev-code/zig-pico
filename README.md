# Zig on the Raspberry Pi Pico
Zig on the Raspberry Pi Pico without losing access to the SDK.

## Requirements
Install the Pico SDK dependencies
```sh
sudo apt install cmake gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib
```

Clone the Pico SDK
```sh
git clone https://github.com/raspberrypi/pico-sdk path/to/pico-sdk
```

Make sure `PICO_SDK_PATH` is set
```sh
export PICO_SDK_PATH path/to/pico-sdk
```

## Usage
Check `build.zig` and `example/main.zig`, it's fairly self explanatory. 

## Build
To build the example for the Pico W
```
zig build
```

## Running
If you have picotool installed, load the resulting `uf2` file
```
picotool load -f zig-out/uf2/pico-app.uf2
```

## Todo
- [x] integrate cmake into zig build
- [x] add include paths of pico libraries to app
- [ ] optimize cmake build steps
- [ ] wrap pico-sdk functions into Pkgs
- [ ] ???
- [ ] profit

### License
MIT
