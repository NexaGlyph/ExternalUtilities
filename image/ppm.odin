package image

import "core:os"
import "core:io"
import "core:log"

/* PPM */
ppm_read2_bgr :: proc(using img: RawImage, file_path: string) {
    img := img;

    handle, ok := os.open(file_path, os.O_RDONLY);
    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open [read] file!");
    }

    file_buffer := fread_all(handle);
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

    switch max_val {
        case UPIXEL_DATA8_MAX:
            img.info = BGR_UUID | (UINT8_UUID << 4);
            break;
        case UPIXEL_DATA16_MAX:
            img.info = BGR_UUID | (UINT16_UUID << 4);
            break;
        case UPIXEL_DATA32_MAX:
            img.info = BGR_UUID | (UINT32_UUID << 4);
            break;
        case:
            assert(false, "invalid max value!");
    }

    assert(false, "TO DO: read buffer!");
}

ppm_write2_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), file_path: string) {
    handle := ppm_header_prepare(file_path, size);
    defer os.close(handle);

    writer_buffer: io.Writer = { os.stream_from_handle(handle) };
    for pxl in data do ppm_write_pixel_bgr(&writer_buffer, pxl);
}

ppm_write2_rgba :: proc(using img: ^Image2(RGBA($PixelType)), file_path: string) {
    handle := ppm_header_prepare(file_path, size);
    defer os.close(handle);

    writer_buffer: io.Writer = { os.stream_from_handle(handle) };
    for pxl in data do ppm_write_pixel_rgba(&writer_buffer, pxl);
}

ppm_header_prepare :: proc(file_path: string, size: ImageSize) -> os.Handle {
    handle, ok := os.open(file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);
    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file!");
    }
    
    write_file(handle, { 'P', '3', '\n' });
    write_file(handle, int_to_string(size.x));
    write_file(handle, { ' ' });
    write_file(handle, int_to_string(size.y));
    write_file(handle, { '\n' });
    write_file(handle, { '2', '5', '5', '\n' });

    return handle;
}

ppm_write_pixel_bgr :: #force_inline proc(writer_buffer: ^io.Writer, val: BGR($PixelDataT)) -> int {
    return ppm_write_pixel_data(writer_buffer, ppm_bgr_pixel_to_bytes(val));
}

ppm_write_pixel_rgba :: #force_inline proc(writer_buffer: ^io.Writer, val: RGBA($PixelDataT)) -> int {
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

ppm_bgr_pixel_to_bytes :: #force_inline proc(val: BGR($PixelDataT)) -> []byte {
    all_bytes: [4 * 11]byte = {};
    i := 0;
    /* R */
    i += pixel_data_to_bytes(val.r.data, all_bytes[i:]);
    /* G */
    i += pixel_data_to_bytes(val.g.data, all_bytes[i:]);
    /* B */
    i += pixel_data_to_bytes(val.b.data, all_bytes[i:]);
    return all_bytes[:i];
}

ppm_rgba_pixel_to_bytes :: #force_inline proc(val: RGBA($PixelDataT)) -> []byte {
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

int_to_bytes :: #force_inline proc(#any_int val: u32) -> []byte {
    if val == 0 do return { '0' };
    bytes: [11]byte = {};
    val := val;
    i := 0;
    for val >= 1 {
        bytes[i] = byte(val % 10 + '0');
        val /= 10;
        i += 1;
    }

    swap :: #force_inline proc(x, y: byte) -> (byte, byte) {
        return y, x;
    }
    for left, right in 0..<i / 2 {
        bytes[left], bytes[i - 1 - right] = swap(bytes[left], bytes[i - 1 - right]);
    }
   
    return bytes[0:i];
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