package utils

import "core:io"

/* signed */
btranspose_32i :: #force_inline proc "fastcall" (value: i32) -> []byte {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
btranspose_16i :: #force_inline proc "fastcall" (value: i16) -> []byte {
    return {
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
/* unsigned */
btranspose_32u :: #force_inline proc "fastcall" (value: u32) -> []byte {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
btranspose_16u :: #force_inline proc "fastcall" (value: u16) -> []byte {
    return {
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}

/* little endian */
btranspose_32i_le :: #force_inline proc "fastcall" (value: i32) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
        cast(u8)(value >> 16),
        cast(u8)(value >> 24),
    };
}

btranspose_16i_le :: #force_inline proc "fastcall" (value: i16) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
    };
}

btranspose_32u_le :: #force_inline proc "fastcall" (value: u32) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
        cast(u8)(value >> 16),
        cast(u8)(value >> 24),
    };
}

btranspose_16u_le :: #force_inline proc "fastcall" (value: u16) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
    };
}

/* signed */
i32_transpose :: #force_inline proc(value: []u8) -> i32 {
    return i32(value[0]) | i32(value[1]) << 8 | i32(value[2]) << 16 | i32(value[3]) << 24;
}
i16_transpose :: #force_inline proc(value: []u8) -> i16 {
    return i16(value[0]) | i16(value[1]) << 8;
}
/* unsigned */
u32_transpose :: #force_inline proc(value: []u8) -> u32 {
    return u32(value[0]) | u32(value[1]) << 8 | u32(value[2]) << 16 | u32(value[3]) << 24;
}
u16_transpose :: #force_inline proc(value: []u8) -> u16 {
    return u16(value[0]) | u16(value[1]) << 8;
}

/* little endian */
i32_le_transpose :: #force_inline proc(value: []u8) -> i32 {
    return i32(value[3]) | i32(value[2] << 8) | i32(value[1] << 16) | i32(value[0]) << 24;
}
i16_le_transpose :: #force_inline proc(value: []u8) -> i16 {
    return i16(value[1]) | i16(value[0] << 8);
}
u32_le_transpose :: #force_inline proc(value: []u8) -> u32 {
    return u32(value[3]) | u32(value[2] << 8) | u32(value[1] << 16) | u32(value[0]) << 24;
}
u16_le_transpose :: #force_inline proc(value: []u8) -> u16 {
    return u16(value[1]) | u16(value[0] << 8);
}

write_file_safe :: proc(writer: io.Writer, data: []byte) {
    size, err := io.write(writer, data);
    when ODIN_DEBUG {
        if err != .None {
            assert(false, "write file failed!");
        }
        assert(size == len(data), "Failed to write whole buffer!");
    }
    else {
        if err != .None {
            assert(false, "think of some useful way to let all parties know...");
        }
    }
}
