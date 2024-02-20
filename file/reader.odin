package file

import "core:os"

Reader :: struct {
    path: string,
    mode: int,
    data: []byte,
    handle: os.Handle,
}

open_reader :: proc(reader: ^Reader) {
    handle, ok := os.open(reader^.path, reader^.mode);
    assert(ok == 0, "failed to open file!");
    reader^.handle = handle;
}

read_from_file :: proc(reader: ^Reader) {
    data: []byte;
    ok: bool;
    if reader^.handle == 0 {
        data, ok = os.read_entire_file_from_filename(
            reader.path,
        );
    }
    else {
        data, ok = os.read_entire_file_from_handle(
            reader.handle,
        );
    }
    assert(ok == true, "failed to read file!");

    reader.data = data;
}

close_reader :: proc(reader: ^Reader) {
    if reader^.handle != 0 {
        ok := os.close(reader^.handle);
        assert(ok == 0, "failed to close file!");
    }
}