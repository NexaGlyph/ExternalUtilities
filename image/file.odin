package image

import "core:strings"
import "core:fmt"
import "core:io"
import "core:bufio"
import "core:os"
import "core:log"

FileFormat :: enum u8 {
    PPM,
    BMP, 
    PNG,
}

FileWriteDescriptor :: struct {
    write_format: FileFormat,
    file_path: string,
}

FileReadDescriptor :: struct {
    read_format: FileFormat,
    file_path: string,
}

/* GENERAL */

/* signed */
btranspose_32i :: #force_inline proc(value: i32) -> []byte {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
btranspose_16i :: #force_inline proc(value: i16) -> []byte {
    return {
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
/* unsigned */
btranspose_32u :: #force_inline proc(value: u32) -> []byte {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}
btranspose_16u :: #force_inline proc(value: u16) -> []byte {
    return {
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}

/* little endian */
btranspose_32i_le :: #force_inline proc(value: i32) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
        cast(u8)(value >> 16),
        cast(u8)(value >> 24),
    };
}

btranspose_16i_le :: #force_inline proc(value: i16) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
    };
}

btranspose_32u_le :: #force_inline proc(value: u32) -> []byte {
    return {
        cast(u8)(value),
        cast(u8)(value >> 8),
        cast(u8)(value >> 16),
        cast(u8)(value >> 24),
    };
}

btranspose_16u_le :: #force_inline proc(value: u16) -> []byte {
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

@(private="package")
write_file :: proc(handle: os.Handle, data: []byte, caller_location := #caller_location) {
    size, err := os.write(handle, data);
    if err != os.ERROR_NONE {
        log.errorf("Failed to write to a file %v", err);
        assert(false);
    }
    assert(size == len(data), "Something went wrong with the writes");
}

@(private="package")
write_file_writer :: proc(writer: io.Writer, data: []byte, caller_location := #caller_location) {
    size, err := io.write(writer, data);
    if err != .None {
        log.errorf("Failed to write to a file %v", err);
        assert(false);
    }
    assert(size == len(data), "Something went wrong with the writes");
}

@(private="package")
@(require_results)
fread :: proc(handle: os.Handle, length: int, caller_location := #caller_location) -> []byte {
    buffer := make([]byte, length);
    _, err := os.read(handle, buffer);
    if err != os.ERROR_NONE {
        log.errorf("Failed to read file %v", err);
        delete(buffer);
        assert(false);
    }
    return buffer;
}

@(private="package")
@(require_results)
fread_all :: proc(handle: os.Handle, caller_location := #caller_location) -> []byte {
    buffer, err := os.read_entire_file_from_handle(handle);
    if err != true {
        log.errorf("Failed to read file %v", err);
        delete(buffer);
        assert(false);
    }
    return buffer;
}

/* IMAGE */
@(private="file")
read_from_file :: proc(using img: ^Image) {
    assert(false, "TO DO!");
}

@(private="file")
write_to_file :: proc(using img: ^Image) {
    assert(false, "TO DO!");
}

/* IMAGE2 */
@(private="file")
read_from_file_bgr :: proc(using img: ^Image2(BGR($PixelData)), frd: FileReadDescriptor) {
    switch frd.read_format {
        case .PPM:
            ppm_read2_bgr(to_raw(img), frd.file_path);
            break;
        case .BMP:
            assert(false, "TO DO!");
        case .PNG:
            assert(false, "TO DO!");
        case:
            assert(false, "Cannot happen...");
    }
}

@(private="file")
read_from_file_rgba :: proc(using img: ^Image2(RGBA($PixelData)), frd: FileReadDescriptor) {
    switch frd.read_format {
        case .PPM:
            assert(false, "TO DO!");
        case .BMP:
            assert(false, "TO DO!");
        case .PNG:
            assert(false, "TO DO!");
        case:
            assert(false, "Cannot happen...");
    }
}

@(private="file")
has_file_type :: proc(file_path: string, type: string) -> bool {
    length := len(file_path);
    return file_path[length - 1] == type[2] && file_path[length - 2] == type[1] && file_path[length - 3] == type[0];
}

@(private="file")
write_to_file_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), fwd: FileWriteDescriptor) {
    switch fwd.write_format {
        case .PPM:
            if has_file_type(fwd.file_path, "ppm") do ppm_write2_bgr(img, fwd.file_path);
            else {
                new_file_path := strings.concatenate({ fwd.file_path, ".ppm" });
                ppm_write2_bgr(img, new_file_path);
                delete(new_file_path);
            }
            break;
        case .BMP:
            if has_file_type(fwd.file_path, "bmp") do bmp_write(img, fwd.file_path);
            else {
                new_file_path := strings.concatenate({ fwd.file_path, ".bmp" });
                bmp_write(img, new_file_path);
                delete(new_file_path);
            } 
        case .PNG:
            if has_file_type(fwd.file_path, "png") do png_write(img, fwd.file_path);
            else {
                new_file_path := strings.concatenate({ fwd.file_path, ".png" });
                png_write(img, new_file_path);
                delete(new_file_path);
            }
        case:
            assert(false, "Cannot happen...");
    }
}

@(private="file")
write_to_file_rgba :: proc(using img: ^Image2(RGBA($PixelDataT)), fwd: FileWriteDescriptor) {
    switch fwd.write_format {
        case .PPM:
            ppm_write2_rgba(img, fwd.file_path);
            break;
        case .BMP:
            assert(false, "TO DO!");
        case .PNG:
            assert(false, "TO DO!");
        case:
            assert(false, "Cannot happen...");
    }
}

read  :: proc { read_from_file, read_from_file_bgr, read_from_file_rgba }
write :: proc { write_to_file,  write_to_file_bgr, write_to_file_rgba }