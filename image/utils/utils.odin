package utils

import "core:io"
import "core:log"
import "core:os"

_4BYTES :: [4]byte;
_2BYTES :: [2]byte;

/* signed */
btranspose_32i :: #force_inline proc "fastcall" (value: i32) -> _4BYTES {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
btranspose_16i :: #force_inline proc "fastcall" (value: i16) -> _2BYTES {
    return {
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
/* unsigned */
btranspose_32u :: #force_inline proc "fastcall" (value: u32) -> _4BYTES {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
btranspose_16u :: #force_inline proc "fastcall" (value: u16) -> _2BYTES {
    return {
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}

/* little endian */
btranspose_32i_le :: #force_inline proc "fastcall" (value: i32) -> _4BYTES {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
        cast(u8)(value >> 16),
        cast(u8)(value >> 24),
    };
}

btranspose_16i_le :: #force_inline proc "fastcall" (value: i16) -> _2BYTES {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
    };
}

btranspose_32u_le :: #force_inline proc "fastcall" (value: u32) -> _4BYTES {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
        cast(u8)(value >> 16),
        cast(u8)(value >> 24),
    };
}

btranspose_16u_le :: #force_inline proc "fastcall" (value: u16) -> _2BYTES {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
    };
}

/* signed */
i32_transpose :: #force_inline proc "contextless" (value: []u8) -> i32 {
    return i32(value[0]) | i32(value[1]) << 8 | i32(value[2]) << 16 | i32(value[3]) << 24;
}
i16_transpose :: #force_inline proc "contextless" (value: []u8) -> i16 {
    return i16(value[0]) | i16(value[1]) << 8;
}
/* unsigned */
u32_transpose :: #force_inline proc "contextless" (value: []u8) -> u32 {
    return u32(value[0]) | u32(value[1]) << 8 | u32(value[2]) << 16 | u32(value[3]) << 24;
}
u16_transpose :: #force_inline proc "contextless" (value: []u8) -> u16 {
    return u16(value[0]) | u16(value[1]) << 8;
}

/* little endian */
i32_le_transpose :: #force_inline proc "contextless" (value: []u8) -> i32 {
    return i32(value[3]) | i32(value[2] << 8) | i32(value[1] << 16) | i32(value[0]) << 24;
}
i16_le_transpose :: #force_inline proc "contextless" (value: []u8) -> i16 {
    return i16(value[1]) | i16(value[0] << 8);
}
u32_le_transpose :: #force_inline proc "contextless" (value: []u8) -> u32 {
    return u32(value[3]) | u32(value[2] << 8) | u32(value[1] << 16) | u32(value[0]) << 24;
}
u16_le_transpose :: #force_inline proc "contextless" (value: []u8) -> u16 {
    return u16(value[1]) | u16(value[0] << 8);
}

write_file_safe :: proc(writer: io.Writer, data: []byte, caller_location := #caller_location) {
    size, err := io.write(writer, data);
    when ODIN_DEBUG {
        if err != .None {
            assert(false, "write file failed!", caller_location);
        }
        assert(size == len(data), "Failed to write whole buffer!", caller_location);
    }
    else {
        if err != .None {
            assert(false, "think of some useful way to let all parties know...");
        }
    }
}

write_file :: proc(handle: os.Handle, data: []byte, caller_location := #caller_location) {
    size, err := os.write(handle, data);
    when ODIN_DEBUG {
        if err != os.ERROR_NONE {
            assert(false, "write file failed!", caller_location);
        }
        assert(size == len(data), "Failed to write whole buffer!", caller_location);
    }
    else {
        if err != os.ERROR_NONE {
            assert(false, "think of some useful way to let all parties know...");
        }
    }
}

@(require_results)
fread :: proc(handle: os.Handle, length: int, caller_location := #caller_location) -> []byte {
    buffer := make([]byte, length);
    size, err := os.read(handle, buffer);
    when ODIN_DEBUG {
        if err != os.ERROR_NONE {
            log.errorf("Failed to read file %v", err);
            delete(buffer);
            assert(false, "", caller_location);
        }
        assert(size == length, "Failed to read whole buffer!", caller_location);
        return buffer;
    }
    else {
        assert(false, "", caller_location);
        return buffer;
    }
}

@(require_results)
fread_all :: proc(handle: os.Handle, caller_location := #caller_location) -> []byte {
    buffer, err := os.read_entire_file_from_handle(handle);
    when ODIN_DEBUG {
        if err != true {
            log.errorf("Failed to read file %v", err);
            delete(buffer);
            assert(false, "", caller_location);
        }
        return buffer;
    }
    else {
        assert(false, "", caller_location);
        return buffer;
    }
}

has_file_type :: #force_inline proc "contextless" (file_path: string, type: string) -> bool {
    length := len(file_path);
    return file_path[length - 1] == type[2] && file_path[length - 2] == type[1] && file_path[length - 3] == type[0];
}