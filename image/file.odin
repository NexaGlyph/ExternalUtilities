package image

import "core:fmt"
import "core:io"
import "core:bufio"
import "core:os"
import "core:log"

FileFormat :: enum u8 {
    PPM,
    JPEG,
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
/* binary */
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
        case .JPEG:
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
        case .JPEG:
            assert(false, "TO DO!");
        case .PNG:
            assert(false, "TO DO!");
        case:
            assert(false, "Cannot happen...");
    }
}

@(private="file")
write_to_file2_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), fwd: FileWriteDescriptor) {
    switch fwd.write_format {
        case .PPM:
            ppm_write2_bgr(img, fwd.file_path);
            break;
        case .JPEG:
            assert(false, "TO DO!");
        case .PNG:
            assert(false, "TO DO!");
        case:
            assert(false, "Cannot happen...");
    }
}

@(private="file")
write_to_file2_rgba :: proc(using img: ^Image2(RGBA($PixelDataT)), fwd: FileWriteDescriptor) {
    switch fwd.write_format {
        case .PPM:
            ppm_write2_rgba(img, fwd.file_path);
            break;
        case .JPEG:
            assert(false, "TO DO!");
        case .PNG:
            assert(false, "TO DO!");
        case:
            assert(false, "Cannot happen...");
    }
}

read  :: proc { read_from_file, read_from_file_bgr, read_from_file_rgba }
write :: proc { write_to_file,  write_to_file2_bgr, write_to_file2_rgba }