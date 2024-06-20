package binary

main :: proc() {
    reader := init_reader();
    defer dump_reader(&reader);
    load(&reader, "file.dat");
}