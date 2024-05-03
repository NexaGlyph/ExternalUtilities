package binary

// import "core:os"

BinaryBuffer :: []u8;

POSITION_UNREAD :: ~u32(0);
Reader :: struct #no_copy {
    buffer: BinaryBuffer,
    pos: u32,
}

init_reader :: proc() -> Reader {
    return {
        nil, POSITION_UNREAD,
    };
}

dump_reader :: proc(using reader: ^Reader) {
    if buffer != nil do delete(buffer);
    pos = POSITION_UNREAD;
}

read :: proc(using reader: ^Reader, fname: string) {
    assert(false);
}

set :: proc(using reader: ^Reader, new_buffer: BinaryBuffer) {
    /* check whether reader's buffer already exists, if yes -> free & rewrite, otherwise just set it */
    assert(false);
    if pos == POSITION_UNREAD do buffer = new_buffer;
    else {
        delete(buffer);
        buffer = new_buffer;
        pos = POSITION_UNREAD;
    }
}

get_byte :: proc(using reader: ^Reader) -> u8 {
    pos += 1;
    return buffer[pos];
}

seek :: proc(using reader: ^Reader, new_pos: u32) -> u32 {
    assert(new_pos >= 0 && pos <= u32(len(buffer)));
    old_pos := pos;
    pos = new_pos;
    return old_pos;
}

tell :: proc(using reader: ^Reader) -> u32 { return pos; }