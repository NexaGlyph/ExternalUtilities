package image

import "core:os"
import "core:log"

FileFormat :: enum u8 {
    PPM,
}

FileWriteDescriptor :: struct {
    write_format: FileFormat,
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

@(private="file")
write_file :: proc(handle: os.Handle, data: []byte, caller_location := #caller_location) {
    _, err := os.write(handle, data);
    if err != os.ERROR_NONE {
        log.errorf("Failed to write to a file %v", err);
        assert(false);
    }
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
read_from_file_bgr :: proc(using img: ^ImageBGR8) {
    assert(false, "TO DO!");
}

// @(private="file")
// read_from_file_urgba :: proc(using img: ^ImageRGBA8) {
//     assert(false, "TO DO!");
// }

@(private="file")
read_from_file_srgba :: proc(using img: ^ImageRGBA8) {
    assert(false, "TO DO!");
}

@(private="file")
write_to_file2_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), fwd: FileWriteDescriptor) {
    switch fwd.write_format {
        case .PPM:
            ppm_write2_bgr(img, fwd.file_path);
            break;
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
        case:
            assert(false, "Cannot happen...");
    }
}

ppm_write2_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), file_path: string) {
    handle := ppm_prepare(file_path, size);
    defer os.close(handle);
    for pxl in data do write_file(handle, { pxl.b.data, ' ', pxl.bgr.g, ' ', pxl.bgr.b, ' ', '\n' });
}

ppm_write2_rgba :: proc(using img: ^Image2(RGBA($PixelType)), file_path: string) {
    handle := ppm_prepare(file_path, size);
    defer os.close(handle);
    for pxl in data do write_file(handle, { pxl.rgba.r, ' ', pxl.rgba.g, ' ', pxl.rgba.b, ' ', pxl.rgba.a, '\n' });
}

ppm_prepare :: proc(file_path: string, size: ImageSize) -> os.Handle {
    handle, ok := os.open(file_path, os.O_WRONLY | os.O_CREATE);
    assert(ok == os.ERROR_NONE, "Failed to open file!");
    
    write_file(handle, { 'P', '3', '\n' });
    write_file(handle, { '5', '0', ' ', '5', '0' });
    write_file(handle, { '\n' });
    write_file(handle, { '2', '5', '5', '\n' });

    return handle;
}

read  :: proc { read_from_file, read_from_file_bgr }
write :: proc { write_to_file,  write_to_file2_bgr, write_to_file2_rgba }