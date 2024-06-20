package binary

import "core:strings"
import "core:os"

BinaryBuffer :: []u8;

POSITION_UNREAD :: u32(0);
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

load :: proc(using reader: ^Reader, fname: string) {
    dump_reader(reader);

    ok := true;

    buffer, ok = os.read_entire_file_from_filename(fname);
    assert(ok == true, "unable to read the file!");
}

peek :: proc(using reader: ^Reader) -> bool {
    return pos >= cast(u32)len(buffer);
}

/* INTEGER READ */
/* note: the reason for ODIN_DEBUG division of read_### functions is to have 'debug' assertions for Reader.pos overflowing Reader.buffer length! */
when ODIN_DEBUG {
    /**
     * @param reader pushes Reader.pos by 1 byte
     * @return byte from Reader.buffer
     */
    read_u8 :: #force_inline proc "odin" (reader: ^Reader) -> (val: u8) {
        assert(!peek(reader), "Reader reached the end of buffer!");

        val = reader^.buffer[reader^.pos];
        reader^.pos += 1;
        return;
    }

    /**
     * >>>NOTE: this function function assumes big endian!
     * @param reader pushes Reader.pos by 2 bytes
     * @return 2 bytes from Reader.buffer as unsigned 16 bit int
     */
    read_u16 :: #force_inline proc "odin" (reader: ^Reader) -> u16 {
        return cast(u16)(read_u8(reader)) | (cast(u16)(read_u8(reader)) << 8);
    }

    /**
     * >>>NOTE: this function function assumes big endian!
     * @param reader pushes Reader.pos by 4 bytes
     * @return 4 bytes from Reader.buffer as unsigned 32 bit int
     */
    read_u32 :: #force_inline proc "odin" (reader: ^Reader) -> u32 {
        return cast(u32)read_i32(reader);
    }

    /**
     * function already assumes integer overflow on the 7th bit and returns its signed equivalent
     * @param reader pushes Reader.pos by 1 byte
     * @return 1 byte from Reader.buffer as signed 8 bit integer
     */
    read_i8 :: proc(reader: ^Reader) -> i8 {
        val := read_u8(reader);
        if (val & (1 << 7)) == val do val -= (1 << 7);
        return i8(val);
    }

    /**
     * >>>NOTE: this function assumes big endian!
     * function already assumes integer overflow on the 15th bit and returns its signed equivalent
     * @param reader pushes Reader.pos by 2 bytes
     * @return 2 bytes from Reader.buffer as signed 16 bit integer
     */
    read_i16 :: #force_inline proc "odin" (reader: ^Reader) -> i16 {
        val := read_u16(reader);
        if (val & 0x8000 /*(1 << 15)*/) == val {
            val -=  (1 << 15);
        }
        return i16(val);
    }

    /**
     * >>>NOTE: this function assumes big endian!
     * @param reader pushes Reader.pos by 4 bytes
     * @return 4 bytes from Reader.buffer as signed 32 bit integer
     */
    read_i32 :: #force_inline proc "odin" (reader: ^Reader) -> i32 {
        return i32(
            (cast(i32) read_u8(reader))        |
            (cast(i32)(read_u8(reader)) << 8)  |
            (cast(i32)(read_u8(reader)) << 16) |
            (cast(i32)(read_u8(reader)) << 24) 
        );
    }
} else {
    read_u8 :: #force_inline proc "contextless" (reader: ^Reader) -> (val: u8) {
        val = reader^.buffer[reader^.pos];
        reader^.pos += 1;
        return;
    }

    read_u16 :: #force_inline proc "contextless" (reader: ^Reader) -> u16 {
        return cast(u16)(read_u8(reader)) | (cast(u16)(read_u8(reader)) << 8);
    }

    read_u32 :: #force_inline proc "contextless" (reader: ^Reader) -> u32 {
        return cast(u32)read_i32(reader);
    }

    read_i8 :: proc(reader: ^Reader) -> i8 {
        val := read_u8(reader);
        if (val & (1 << 7)) == val do val -= (1 << 7);
        return i8(val);
    }

    read_i16 :: #force_inline proc "contextless" (reader: ^Reader) -> i16 {
        val := read_u16(reader);
        if (val & 0x8000 /*(1 << 15)*/) == val {
            val -=  (1 << 15);
        }
        return i16(val);
    }

    read_i32 :: #force_inline proc "contextless" (reader: ^Reader) -> i32 {
        return i32(
            (cast(i32) read_u8(reader))        |
            (cast(i32)(read_u8(reader)) << 8)  |
            (cast(i32)(read_u8(reader)) << 16) |
            (cast(i32)(read_u8(reader)) << 24) 
        );
    }
}
/*! INTEGER READ */

/* BYTE READ */
/**
 * @see read_u8
 */
read_byte :: read_u8;

/**
 * generic function to parse string from Reader.buffer such that it terminates on "termination sign"
 * @param reader is used to read all the bytes of the reader's buffer until "\0" sign
 * @param termination_sign
 */
read_string_terminated :: proc(reader: ^Reader, termination_sign: byte) -> string {
    builder := strings.Builder{};
    _, err := strings.builder_init(&builder);
    assert(err == nil, "Failed to initialize String Builder!");

    char := read_byte(reader); 
    for char != termination_sign {
        strings.write_byte(&builder, char);
        char = read_byte(reader);
    }

    return strings.to_string(builder);
}

/**
 * useful when interfering with C-generated-strings
 * convenient function for abstracting termination_sign param from @see read_string_terminated function
 * @param reader is used to read all the bytes of the reader's buffer until "\0" sign
 */
read_string_null_terminated :: #force_inline proc(reader: ^Reader) -> string {
    return read_string_terminated(reader, 0);
}

/**
 * useful when reading strings terminated by EOL (LF) in files
 * abstracts @see read_string_terminated with default termination_sign param
 * @param reader is used to read all the bytes of the reader's buffer until "\0" sign
 */
read_string_eol_terminated :: #force_inline proc(reader: ^Reader) -> string {
    return read_string_terminated(reader, 0x0a);
}

/**
 * @param reader
 * @param len is used to slice the reader's buffer (Reader.buffer) for this given length, note: null termination not checked!
 */
read_string :: proc(reader: ^Reader, len: int) -> string {
    previous_pos := reader^.pos;
    reader^.pos += cast(u32)len;
    return string(reader^.buffer[previous_pos:reader^.pos]);
}

read_nbytes :: #force_inline proc(reader: ^Reader, len: u32) -> []byte {
    bytes := reader^.buffer[reader^.pos:reader^.pos + len];
    reader^.pos += len;
    return bytes;
}

read_nbytes_static :: #force_inline proc(reader: ^Reader, $len: u32) -> (bytes: [len]byte) {
    copy_slice(bytes[:], reader^.buffer[reader^.pos:reader^.pos + len]);
    reader^.pos += len;
    return;
}
/*! BYTE READ */

/* READER MOVE */
set :: proc(using reader: ^Reader, new_buffer: BinaryBuffer) {
    /* check whether reader's buffer already exists, if yes -> free & rewrite, otherwise just set it */
    if buffer == nil do buffer = new_buffer;
    else {
        delete(buffer);
        buffer = new_buffer;
        pos = POSITION_UNREAD;
    }
}

seek :: proc(using reader: ^Reader, new_pos: u32) -> u32 {
    assert(new_pos >= 0 && pos <= u32(len(buffer)));
    old_pos := pos;
    pos = new_pos;
    return old_pos;
}

tell :: #force_inline proc(using reader: ^Reader) -> u32 { return pos; }
/*! READER MOVE */