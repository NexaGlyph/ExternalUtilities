package image

import "core:io"
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
// @(private="file")
// read_from_file_bgr :: proc(using img: ^Image2(BGR($PixelData)), frd: FileReadDescriptor) {
//     switch frd.read_format {
//         case .PPM:
//             ppm.read2_bgr(to_raw(img), frd.file_path);
//             break;
//         case .BMP:
//             assert(false, "TO DO!");
//         case .PNG:
//             assert(false, "TO DO!");
//         case:
//             assert(false, "Cannot happen...");
//     }
// }

// @(private="file")
// read_from_file_rgba :: proc(using img: ^Image2(RGBA($PixelData)), frd: FileReadDescriptor) {
//     switch frd.read_format {
//         case .PPM:
//             assert(false, "TO DO!");
//         case .BMP:
//             assert(false, "TO DO!");
//         case .PNG:
//             assert(false, "TO DO!");
//         case:
//             assert(false, "Cannot happen...");
//     }
// }

// @(private="file")
// has_file_type :: proc(file_path: string, type: string) -> bool {
//     length := len(file_path);
//     return file_path[length - 1] == type[2] && file_path[length - 2] == type[1] && file_path[length - 3] == type[0];
// }

// @(private="file")
// write_to_file_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), fwd: FileWriteDescriptor) {
//     switch fwd.write_format {
//         case .PPM:
//             if has_file_type(fwd.file_path, "ppm") do ppm.write2_bgr(img, fwd.file_path);
//             else {
//                 new_file_path := strings.concatenate({ fwd.file_path, ".ppm" });
//                 ppm.write2_bgr(img, new_file_path);
//                 delete(new_file_path);
//             }
//             break;
//         case .BMP:
//             if has_file_type(fwd.file_path, "bmp") do bmp.write(img, fwd.file_path);
//             else {
//                 new_file_path := strings.concatenate({ fwd.file_path, ".bmp" });
//                 bmp.write(img, new_file_path);
//                 delete(new_file_path);
//             } 
//         case .PNG:
//             if has_file_type(fwd.file_path, "png") do png.write(img, fwd.file_path);
//             else {
//                 new_file_path := strings.concatenate({ fwd.file_path, ".png" });
//                 png.write(img, new_file_path);
//                 delete(new_file_path);
//             }
//         case:
//             assert(false, "Cannot happen...");
//     }
// }

// @(private="file")
// write_to_file_rgba :: proc(using img: ^Image2(RGBA($PixelDataT)), fwd: FileWriteDescriptor) {
//     switch fwd.write_format {
//         case .PPM:
//             ppm.write2_rgba(img, fwd.file_path);
//             break;
//         case .BMP:
//             assert(false, "TO DO!");
//         case .PNG:
//             assert(false, "TO DO!");
//         case:
//             assert(false, "Cannot happen...");
//     }
// }

// read  :: proc { read_from_file, read_from_file_bgr, read_from_file_rgba }
// write :: proc { write_to_file,  write_to_file_bgr, write_to_file_rgba }