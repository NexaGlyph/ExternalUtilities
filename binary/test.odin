package binary

main :: proc() {
    reader := init_reader();
    defer dump_reader(&reader);
    read(&reader, "file.dat");
}