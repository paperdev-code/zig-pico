##### Update
I am thinking about doing a rewrite.
Currently, this code does not compile on Zig 0.10.x and I think there's lots to be improved here which I am planning to do in the coming weeks.

I am not archiving this repository because it will likely be on some branch here `refactor`. But it will contain major breaking changes.

I think the idea of handling the entire CMake project is still very much the best way to do this weird project. I am hopeful Clang support will improve to replace `gcc` with `zig cc`, so I will keep this sort of thing in mind during the rewrite.

Hopefully by the end, it will be easier to actually maintain and I can make some neat zig wrappers for the sdk.

###### - Paperdev

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
