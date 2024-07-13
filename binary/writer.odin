package binary

import "core:fmt"
import "core:os"

Writer :: struct {
    fhandle: os.Handle,
}

init_writer :: #force_inline proc(fpath: string) -> Writer {
    writer := Writer{};
    err: os.Errno;
    writer.fhandle, err = os.open(fpath, os.O_WRONLY | os.O_CREATE);
    // fmt.printf("%s\n%v\n", fpath, err);
    assert(err == os.ERROR_NONE, "Failed to open file for reading!");
    return writer;
}

dump_writer :: #force_inline proc(using writer: ^Writer) {
    os.close(fhandle);
}

/* BYTE WRITE */
write_bytes :: #force_inline proc(using writer: ^Writer, bytes: []byte) {
    written, err := os.write(fhandle, bytes);
    fmt.printf("Error write bytes: %v\n", err);
    assert(err == os.ERROR_NONE, "Failed to write buffer!");
    assert(written == len(bytes), "Failed to write whole buffer!");
}
/*! BYTE WRITE */