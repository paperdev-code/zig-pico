// C entry point which defined the main function.
// Figure out how to change entry point to just have the 'main' definable in zig.
extern void init();
extern void loop();

int main() {
    init();
    while (1) loop();
}

