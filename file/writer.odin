package file

import "core:os"

Writer :: struct {
    path: string,
    mode: int,
    data: []byte,
    data_len: int,
    handle: os.Handle,
}

open_writer :: proc(writer: ^Writer) {
    handle, ok := os.open(writer^.path, writer^.mode);
    assert(ok == 0, "failed to open file");
    writer^.handle = handle;
}

write_to_file :: proc(writer: ^Writer) {
    if writer^.handle == 0 {
        // handle, ok := os.open(writer^.path, writer^.mode);
        // assert(ok == 0, "failed to open file");
        // writer^.handle = handle;
        ok := os.write_entire_file(writer^.path, writer^.data);
        assert(ok == true, "failed to write entire file!");
    }
    else {
        total_write, ok := os.write(writer^.handle, writer^.data);
        assert(ok == 0, "failed to write to file!");
        assert(total_write == len(writer^.data), "not whole file was written!");
    }
}

close_writer :: proc(writer: ^Writer) {
    if writer^.handle != 0 {
        ok := os.close(writer^.handle);
        assert(ok == 0, "failed to close file!");
    }
}