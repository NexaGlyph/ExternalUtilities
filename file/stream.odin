package file

/*>>>NOTE: HOW TO FIX STREAMING BOTH READER AND WRITER ???? <<<*/
FStream :: struct {
    reader: ^Reader,
    writer: ^Writer
}

open :: proc(
    Rmode: int,
    Rpath: string,
    Wmode: int,
    Wpath: string
)
{
    /* check for O_RDONLY */

    /* check for O_WRONLY */

    /* check for O_RDWR, NOTE: TO SEE FOR ASYNC */
}

read :: proc(fstream: ^FStream) {
    read_from_file(fstream^.reader);
}

write :: proc(fstream: ^FStream) {
    write_to_file(fstream^.writer);
}

get_reader :: proc(fstream: ^FStream) -> ^Reader {
    return fstream^.reader;
}

get_writer :: proc(fstream: ^FStream) -> ^Writer {
    return fstream^.writer;
}

close :: proc(fstream: ^FStream) {
    close_reader(fstream^.reader);
    free(fstream^.reader);
    close_writer(fstream^.writer);
    free(fstream^.writer);
}