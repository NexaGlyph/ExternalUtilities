package ppm

import "core:os"
import "core:io"
import "core:log"

import "../../image"
import "../utils"

/* PPM */
ppm_read2_bgr :: proc(using img: image.RawImage, file_path: string) {
    img := img;

    handle, ok := os.open(file_path, os.O_RDONLY);
    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open [read] file!");
    }

    file_buffer := utils.fread_all(handle);
    defer delete(file_buffer);
    if file_buffer[0] != 'P' || file_buffer[1] != '3' {
        assert(false, "Failed to read file! File Header is corrupted");
    }

    i, previous := 3, 3;
    for {
        if file_buffer[i] == ' ' {
            img.size.x = parse_integer(file_buffer[previous : i]);
            previous = i;            
        }
        else if file_buffer[i] == '\n' {
            img.size.y = parse_integer(file_buffer[previous : i]);
            break;
        }
        i += 1;
    }

    max_val := u32(0);
    for file_buffer[i] != '\n' {
        max_val *= 10;
        max_val += u32(file_buffer[i]);
        i += 1;
    }

    {
        switch max_val {
            case image.UPIXEL_DATA8_MAX:
                img.info = image.BGR_UUID | (image.UINT8_UUID << 4);
                break;
            case image.UPIXEL_DATA16_MAX:
                img.info = image.BGR_UUID | (image.UINT16_UUID << 4);
                break;
            case image.UPIXEL_DATA32_MAX:
                img.info = image.BGR_UUID | (image.UINT32_UUID << 4);
                break;
            case:
                assert(false, "invalid max value!");
        }
    }

    assert(false, "TO DO: read buffer!");
}

// ppm_write2_bgr :: proc(using img: ^image.Image2(image.BGR($PixelDataT)), file_path: string) {
//     handle := ppm_header_prepare(file_path, size);
//     defer os.close(handle);
//     number_array: [11]byte = {};
//     for pxl in data {
//         // fmt.printf("%v :: ", number_array[:int_to_bytes(number_array[:], pxl.r.data)]);
//         // number_array = {};
//         // fmt.printf("%v\n", int_to_string(pxl.r.data));
//         utils.write_file(handle, number_array[:int_to_bytes(number_array[:], pxl.r.data)]);
//         number_array = {};
//         utils.write_file(handle, {' '});
//         utils.write_file(handle, number_array[:int_to_bytes(number_array[:], pxl.g.data)]);
//         number_array = {};
//         utils.write_file(handle, {' '});
//         utils.write_file(handle, number_array[:int_to_bytes(number_array[:], pxl.b.data)]);
//         number_array = {};
//         utils.write_file(handle, {'\n'});
//     }
// }

ppm_write2_bgr :: proc(using img: ^image.ImageBGR8, file_path: string) {
    handle := ppm_header_prepare(file_path, size);
    defer os.close(handle);

    #no_bounds_check number_array: [3]byte = {};
    #no_bounds_check buffer: [1000]byte = {};
    buffer_index, num_bytes := 0, 0;
    for pxl in data {
        num_bytes = int_to_bytes(number_array[:], pxl.r.data);
        if buffer_index + num_bytes >= len(buffer) {
            utils.write_file(handle, buffer[:buffer_index]);
            buffer_index = 0;
        }
        copy(buffer[buffer_index:buffer_index + num_bytes], number_array[:num_bytes]);
        buffer[buffer_index + num_bytes] = ' ';
        buffer_index += num_bytes + 1;

        num_bytes = int_to_bytes(number_array[:], pxl.g.data);
        if buffer_index + num_bytes >= len(buffer) {
            utils.write_file(handle, buffer[:buffer_index]);
            buffer_index = 0;
        }
        copy(buffer[buffer_index:buffer_index + num_bytes], number_array[:num_bytes]);
        buffer[buffer_index + num_bytes] = ' ';
        buffer_index += num_bytes + 1;

        num_bytes = int_to_bytes(number_array[:], pxl.b.data);
        if buffer_index + num_bytes >= len(buffer) {
            utils.write_file(handle, buffer[:buffer_index]);
            buffer_index = 0;
        }
        copy(buffer[buffer_index:buffer_index + num_bytes], number_array[:num_bytes]);
        buffer[buffer_index + num_bytes] = '\n';
        buffer_index += num_bytes + 1;
    }

    if buffer_index > 0 {
        utils.write_file(handle, buffer[:buffer_index]);
    }
}

ppm_write2_rgba :: proc(using img: ^image.Image2(image.RGBA($PixelType)), file_path: string) {
    assert(false, "todo: refactor");
    handle := ppm_header_prepare(file_path, size);
    defer os.close(handle);

    writer_buffer: io.Writer = { os.stream_from_handle(handle) };
    for pxl in data do ppm_write_pixel_rgba(&writer_buffer, pxl);
}

ppm_header_prepare :: proc(file_path: string, size: image.ImageSize) -> os.Handle {
    handle, ok := os.open(file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);
    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file!");
    }
    
    utils.write_file(handle, { 'P', '3', '\n' });
    size_val := int_to_string(size.x);
    utils.write_file(handle, size_val);
    delete(size_val);
    utils.write_file(handle, { ' ' });
    size_val = int_to_string(size.y);
    utils.write_file(handle, size_val);
    delete(size_val);
    utils.write_file(handle, { '\n' });
    utils.write_file(handle, { '2', '5', '5', '\n' });

    return handle;
}

ppm_write_pixel_bgr :: #force_inline proc(writer_buffer: ^io.Writer, val: image.BGR($PixelDataT)) -> int {
    return ppm_write_pixel_data(writer_buffer, ppm_bgr_pixel_to_bytes(val));
}

ppm_write_pixel_rgba :: #force_inline proc(writer_buffer: ^io.Writer, val: image.RGBA($PixelDataT)) -> int {
    return ppm_write_pixel_data(writer_buffer, ppm_rgba_pixel_to_bytes(val));
}

ppm_write_pixel_data :: #force_inline proc(writer_buffer: ^io.Writer, val: []byte) -> int {
    // size, err := bufio.writer_write(writer_buffer, val);
    size, err := io.write(writer_buffer^, val);
    if err != .None {
        log.errorf("%v", err);
        assert(false, "Failed to write to writer_buffer!");
    }
    return size;
}

ppm_bgr_pixel_to_bytes :: #force_inline proc(val: image.BGR($PixelDataT)) -> []byte {
    all_bytes: [4 * 11]byte = {};
    i := 0;
    /* R */
    i += pixel_data_to_bytes(val.r.data, all_bytes[i:]);
    fmt.printf("%v, ", all_bytes[0:i]);
    /* G */
    prev_i := i
    i += pixel_data_to_bytes(val.g.data, all_bytes[i:]);
    fmt.printf("%v, ", all_bytes[prev_i:i]);
    /* B */
    prev_i = i;
    i += pixel_data_to_bytes(val.b.data, all_bytes[i:]);
    fmt.printf("%v\n", all_bytes[prev_i:i]);
    all_bytes[i] = '\n';
    i += 1;
    return all_bytes[:i];
}

ppm_rgba_pixel_to_bytes :: #force_inline proc(val: image.RGBA($PixelDataT)) -> []byte {
    all_bytes: [4 * 11]byte = {};
    i := 0;
    /* R */
    i += pixel_data_to_bytes(val.r.data, all_bytes[i:]);
    /* G */
    i += pixel_data_to_bytes(val.g.data, all_bytes[i:]);
    /* B */
    i += pixel_data_to_bytes(val.b.data, all_bytes[i:]);
    /* A */
    i += pixel_data_to_bytes(val.a.data, all_bytes[i:]);
    return all_bytes[:i];
}

pixel_data_to_bytes :: #force_inline proc(val: $PixelDataT, pixel_bytes: []byte) -> int {
    bytes := int_to_bytes(val);
    nbytes := len(bytes);
    copy(pixel_bytes[:nbytes], bytes);
    pixel_bytes[nbytes] = byte(' ');
    return nbytes + 1;
}

int_to_bytes :: #force_inline proc(buffer: []byte, #any_int val: u32) -> int {
    if val == 0 {
        buffer[0] = '0';
        return 1;
    }
    val := val;
    i := 0;
    for val >= 1 {
        buffer[i] = byte(val % 10 + '0');
        val /= 10;
        i += 1;
    }

    swap :: #force_inline proc "fastcall" (x, y: byte) -> (byte, byte) {
        return y, x;
    }
    for left, right in 0..<i / 2 {
        buffer[left], buffer[i - 1 - right] = swap(buffer[left], buffer[i - 1 - right]);
    }
   
    return i;
}

DIGITS := "0123456789";
int_to_string :: #force_inline proc(#any_int val: u64) -> []byte {
    buf := make([]byte, 32);
    a: [129]byte;
	i := len(a);
	b :: u64(10);
    val := val;
	for val >= b {
		i-=1; a[i] = DIGITS[val % b];
		val /= b;
	}
	i-=1; a[i] = DIGITS[val % b];

	out := a[i:]
	copy(buf, out);
    return buf[0:len(out)];
}

@(private="file")
parse_integer :: proc(s: []byte) -> u32 {
    result := u32(0);
    for c in s {
        result *= 10;
        result += u32(c - '0');
    }
    return result;
}