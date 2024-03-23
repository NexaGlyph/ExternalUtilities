package bmp

import "core:io"
import "core:os"
import "core:log"
import "core:strings"

import "../../image"
import "../utils"

/* ALL OF THE OTHER ERRORS (LIKE IN WRITING) ARE USUALLY CAUGHT WITH THE UITLITY FUNCTIONS AND ARE ASSERTED */
BMP_Error :: enum {
    E_NONE,
    E_UNRECOGNIZED_FILE_SIZE,
    E_READ_INVALID_FILE_FORMAT,
    E_READ_UNSUPPORTED_BIT_DEPTH,
    E_READ_UNSUPPORTED_COMPRESSION_METHOD,
    E_READ_INSUFFICIENT_MEMORY,
    E_READ_CORRUPTED_DATA,
    E_READ_UNEXPECTED_END_OF_FILE,
}

BMP_MAGIC_ID :: 2;

bmpfile_magic :: struct {
    magic: [BMP_MAGIC_ID]u8,
}

bmpfile_header :: struct {
    file_size: u32,
    creator1: u16,
    creator2: u16,
    bmp_offset: u32,
}
/* 432 = 16 + 96 + 320 */
BMP_OFFSET :: (2 * size_of(u8)) + (2 * size_of(u32) + 2 * size_of(u16)) + (5 * size_of(u32) + 4 * size_of(i32) + 2 * size_of(u16))

bmpfile_dib_info :: struct {
    header_size: u32,
    width: i32,
    height: i32,
    num_planes: u16,
    bits_per_pixel: u16,
    compression: u32,
    bmp_byte_size: u32,
    hres: i32,
    vres: i32,
    num_colors: u32,
    num_important_colors: u32,
}

init_header :: proc(size: image.ImageSize) -> bmpfile_header {
    return {
        file_size  = BMP_OFFSET + size.x * size.y * 4,
        creator1   = u16(0),
        creator2   = u16(0),
        bmp_offset = BMP_OFFSET, 
    };
}

init_dib :: proc(size: image.ImageSize, bit_depth: u16) -> bmpfile_dib_info {
    return {
        header_size = size_of(bmpfile_dib_info),
        width = i32(size.x),
        height = i32(size.y),
        num_planes = 1,
        bits_per_pixel = bit_depth,
        compression = 0,
        bmp_byte_size = 0,
        hres = 2835,
        vres = 2835,
        num_colors = 0,
        num_important_colors = 0,
    };
}

/* BMP WRITE */
bmp_write_bgr :: proc(using img: ^image.Image2($PixelT), file_path: string) {
    handle := _bmp_write_begin(file_path);
    writer: io.Writer = os.stream_from_handle(handle);
    defer os.close(handle);
    defer io.destroy(writer);
   
    _bmp_write_magic(writer);
    _bmp_write_header(writer, init_header(size));
    log.infof("%v", size_of(PixelT));
    _bmp_write_dib(writer, init_dib(size, 8 * size_of(PixelT)));
    bmp_array := _bmp_data_convert(data, size);
    defer delete(bmp_array);
    _bmp_write_data(writer, bmp_array);
}

bmp_write_rgba :: proc() {
    assert(false, "TO DO!");
}

bmp_write :: proc { bmp_write_bgr, bmp_write_rgba }

@(private="file")
_bmp_write_begin :: proc(file_path: string) -> os.Handle {
    handle: os.Handle;
    ok: os.Errno;
    {
        if utils.has_file_type(file_path, "bmp") do handle, ok = os.open(file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);
        else {
            new_file_path := strings.concatenate({ file_path, ".bmp" });
            handle, ok = os.open(new_file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);
            delete(new_file_path);
        }
    }

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file [png] for writing");
    }

    return handle;
}

@(private="file")
_bmp_write_magic :: #force_inline proc(writer: io.Writer) {
    utils.write_file_safe(writer, { 'B', 'M' });
}

@(private="file")
_bmp_write_header :: #force_inline proc(writer: io.Writer, header: bmpfile_header) {
    header_array: [12]u8 = {};

    _2byte_array: utils._2BYTES = utils.btranspose_16u_le(header.creator1);
    _4byte_array: utils._4BYTES = utils.btranspose_32u_le(header.file_size);
    copy(header_array[:], _4byte_array[:]);
    copy(header_array[4:], _2byte_array[:]);

    _2byte_array = utils.btranspose_16u_le(header.creator2);
    _4byte_array = utils.btranspose_32u_le(header.bmp_offset);
    copy(header_array[6:], _2byte_array[:]);
    copy(header_array[8:], _4byte_array[:]);

    // log.infof("HEADER ARRAY: %v", header_array);
    utils.write_file_safe(writer, header_array[:]);
}

@(private="file")
write_transformed_field_u32 :: #force_inline proc(dib_array: []u8, start: int, end: int, field: u32, transformer: proc "fastcall" (u32) -> utils._4BYTES) {
    transformed_field := transformer(field);
    copy(dib_array[start:end], transformed_field[:]);
}

@(private="file")
write_transformed_field_u16 :: #force_inline proc(dib_array: []u8, start: int, end: int, field: u16, transformer: proc "fastcall" (u16) -> utils._2BYTES) {
    transformed_field := transformer(field);
    copy(dib_array[start:end], transformed_field[:]);
}

@(private="file")
write_transformed_field_i32 :: #force_inline proc(dib_array: []u8, start: int, end: int, field: i32, transformer: proc "fastcall" (i32) -> utils._4BYTES) {
    transformed_field := transformer(field);
    copy(dib_array[start:end], transformed_field[:]);
}

@(private="file")
write_transformed_field_i16 :: #force_inline proc(dib_array: []u8, start: int, end: int, field: i16, transformer: proc "fastcall" (i16) -> utils._2BYTES) {
    transformed_field := transformer(field);
    copy(dib_array[start:end], transformed_field[:]);
}

@(private="file")
write_transformed_field :: proc {
    write_transformed_field_i16, write_transformed_field_i32, write_transformed_field_u16, write_transformed_field_u32,
}

@(private="file")
_bmp_write_dib :: #force_inline proc(writer: io.Writer, dib: bmpfile_dib_info) {
    dib_array: [44]u8 = {};    
    write_transformed_field(dib_array[:], 0, 4,   dib.header_size, utils.btranspose_32u_le);
    write_transformed_field(dib_array[:], 4, 8,   dib.width, utils.btranspose_32i_le);
    write_transformed_field(dib_array[:], 8, 12,  dib.height, utils.btranspose_32i_le);
    write_transformed_field(dib_array[:], 12, 14, dib.num_planes, utils.btranspose_16u_le);
    write_transformed_field(dib_array[:], 14, 16, dib.bits_per_pixel, utils.btranspose_16u_le);
    write_transformed_field(dib_array[:], 16, 20, dib.compression, utils.btranspose_32u_le);
    write_transformed_field(dib_array[:], 20, 24, dib.bmp_byte_size, utils.btranspose_32u_le);
    write_transformed_field(dib_array[:], 24, 28, dib.hres, utils.btranspose_32i_le);
    write_transformed_field(dib_array[:], 28, 32, dib.vres, utils.btranspose_32i_le);
    write_transformed_field(dib_array[:], 32, 36, dib.num_colors, utils.btranspose_32u_le);
    write_transformed_field(dib_array[:], 36, 40, dib.num_important_colors, utils.btranspose_32u_le);

    // log.infof("%v", dib_array);

    utils.write_file_safe(writer, dib_array[:]);
}

@(private="file")
_bmp_data_convert8 :: #force_inline proc(data_before: []image.BGR8, size: image.ImageSize) -> []u8 {
    #no_bounds_check data_after := make([]u8, len(data_before) * 4);

    bgr: image.BGR8;
    for y in 0..<size.y {
        for x in 0..<size.x {
            bgr = data_before[y * size.x + x];
            data_after[(y*size.x + x)*4 + 0] = bgr.r.data;
            data_after[(y*size.x + x)*4 + 1] = bgr.g.data;
            data_after[(y*size.x + x)*4 + 2] = bgr.b.data;
            data_after[(y*size.x + x)*4 + 3] = 0;
        }
    }

    return data_after;
}

@(private="file")
_bmp_data_convert16 :: #force_inline proc(data_before: []image.BGR16, size: image.ImageSize) -> []u8 {    
    #no_bounds_check data_after := make([]u8, len(data_before) * 4 * size_of(u16));

    pos: u32;
    bgr: image.BGR16;
    _2byte_array: utils._2BYTES; 
    for y in 0..<size.y {
        for x in 0..<size.x {
            pos = y * size.x + x;
            bgr = data_before[pos];
            {
                _2byte_array = utils.btranspose_16u(bgr.r.data);
                data_after[pos * 4 + 0] = _2byte_array[0];
                data_after[pos * 4 + 1] = _2byte_array[1];
            }
            {
                _2byte_array = utils.btranspose_16u(bgr.g.data);
                data_after[pos * 4 + 2] = _2byte_array[0];
                data_after[pos * 4 + 3] = _2byte_array[1];
            }
            {
                _2byte_array = utils.btranspose_16u(bgr.b.data);
                data_after[pos * 4 + 4] = _2byte_array[0];
                data_after[pos * 4 + 5] = _2byte_array[1];
            }
            {
                data_after[pos * 4 + 6] = 0;
                data_after[pos * 4 + 7] = 0;
            }
        }
    }

    return data_after;
}

@(private="file")
_bmp_data_convert32 :: #force_inline proc(data_before: []image.BGR32, size: image.ImageSize) -> []u8 {    
    #no_bounds_check data_after := make([]u8, len(data_before) * 4 * size_of(u32));

    pos: u32;
    bgr: image.BGR32;
    _4byte_array: utils._4BYTES;
    for y in 0..<size.y {
        for x in 0..<size.x {
            pos = y * size.x + x;
            bgr = data_before[pos];
            {
                _4byte_array = utils.btranspose_32u(bgr.r.data);
                data_after[pos * 4 + 0] = _4byte_array[0];
                data_after[pos * 4 + 1] = _4byte_array[1];
                data_after[pos * 4 + 2] = _4byte_array[2];
                data_after[pos * 4 + 3] = _4byte_array[3];
            }
            {
                _4byte_array = utils.btranspose_32u(bgr.g.data);
                data_after[pos * 4 + 4] = _4byte_array[0];
                data_after[pos * 4 + 5] = _4byte_array[1];
                data_after[pos * 4 + 6] = _4byte_array[0];
                data_after[pos * 4 + 7] = _4byte_array[1];
            }
            {
                _4byte_array = utils.btranspose_32u(bgr.b.data);
                data_after[pos * 4 + 8]  = _4byte_array[0];
                data_after[pos * 4 + 9]  = _4byte_array[1];
                data_after[pos * 4 + 10] = _4byte_array[2];
                data_after[pos * 4 + 11] = _4byte_array[3];
            }
            {
                data_after[pos * 4 + 12] = 0;
                data_after[pos * 4 + 13] = 0;
                data_after[pos * 4 + 14] = 0;
                data_after[pos * 4 + 15] = 0;
            }
        }
    }

    return data_after;
}

@(private="file")
_bmp_data_convert :: proc { _bmp_data_convert8, _bmp_data_convert16, _bmp_data_convert32 }

@(private="file")
_bmp_write_data :: #force_inline proc(writer: io.Writer, data: []u8) {
    // log.infof("%v", data);
    utils.write_file_safe(writer, data);
}

/* BMP READ */
bmp_read_bgr_auto :: proc(file_path: string) -> (img: image.RawImage, err: BMP_Error) {
    handle, ok := os.open(file_path, os.O_RDONLY);
    defer os.close(handle);

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file [png] for writing");
    }
    
    reader: io.Reader = os.stream_from_handle(handle);

    _bmp_read_magic(reader) or_return;
    header := _bmp_read_header(reader, Header_ExpectedValues { BMP_OFFSET }) or_return;
    dib    := _bmp_read_dib(reader, DIB_ExpectedValues { 24 }) or_return;
    data   := _bmp_read_data(reader, dib, Data_ExpectedValues { int(header.file_size - header.bmp_offset) }) or_return;
    img.data = &data[0];
    img.size = image.IMAGE_SIZE(dib.width, dib.height);
    return {}, .E_NONE;
}

bmp_read_bgr8 :: proc(file_path: string) -> (img: image.ImageBGR8, err: BMP_Error) {
    handle, ok := os.open(file_path, os.O_RDONLY);
    defer os.close(handle);

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file [png] for writing");
    }
    
    reader: io.Reader = os.stream_from_handle(handle);

    _bmp_read_magic(reader)               or_return;
    header := _bmp_read_header(reader, Header_ExpectedValues { BMP_OFFSET }) or_return;
    dib    := _bmp_read_dib(reader, DIB_ExpectedValues { 24 }) or_return;
    data   := _bmp_read_data(reader, dib, Data_ExpectedValues { int(header.file_size - header.bmp_offset) }) or_return;
    return {}, .E_NONE;
}

bmp_read_bgr16 :: proc() -> image.ImageBGR16 {
    return {};
}

bmp_read_bgr32 :: proc() -> image.ImageBGR32 {
    return {};
}

validate_magic :: #force_inline proc "fastcall" (magic: [2]u8) -> BMP_Error {
    if magic[0] != 'B' || magic[1] != 'M' do return .E_READ_INVALID_FILE_FORMAT;
    return .E_NONE;
}

@(private="file")
_bmp_read_magic :: proc(reader: io.Reader) -> BMP_Error {
    magic := [2]u8{};
    io.read(reader, magic[:]);
    return validate_magic(magic);
}

Header_ExpectedValues :: struct {
    bmp_offset: u32,
}

@(private="file")
_bmp_read_header :: proc(reader: io.Reader, expected: Header_ExpectedValues) -> (bmpfile_header, BMP_Error) {
    header_binary := make([]u8, size_of(bmpfile_header));
    defer delete(header_binary);

    io.read(reader, header_binary);
    header := bmpfile_header{};
    {
        next := 0;
        header.file_size  = utils.u32_le_transpose(header_binary[next:next + size_of(u32)]);
        if header.file_size == 0 do return {}, .E_UNRECOGNIZED_FILE_SIZE;
        next += size_of(u32);
        header.creator1   = utils.u16_le_transpose(header_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        header.creator2   = utils.u16_le_transpose(header_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        header.bmp_offset = utils.u32_le_transpose(header_binary[next:next + size_of(u32)]);
        if header.bmp_offset != expected.bmp_offset do return {}, .E_READ_CORRUPTED_DATA;
    }

    return header, .E_NONE;
}

DIB_ExpectedValues :: struct {
    bit_depth: u16,
}

@(private="file")
_bmp_read_dib :: proc(reader: io.Reader, expected: DIB_ExpectedValues) -> (bmpfile_dib_info, BMP_Error) {
    dib_binary := make([]u8, size_of(bmpfile_dib_info));
    defer delete(dib_binary);

    io.read(reader, dib_binary);
    dib := bmpfile_dib_info{};
    {
        next := 0;
        // header size
        dib.header_size = utils.u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // width
        dib.width   = utils.i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // height
        dib.height = utils.i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // number of planes
        dib.num_planes = utils.u16_le_transpose(dib_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        // bit depth
        dib.bits_per_pixel = utils.u16_le_transpose(dib_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        // compression
        dib.compression = utils.u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // byte size
        dib.bmp_byte_size = utils.u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // hres
        dib.hres = utils.i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // vres
        dib.vres = utils.i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // palette
        dib.num_colors = utils.u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // important colors
        dib.num_important_colors = utils.u32_le_transpose(dib_binary[next:next + size_of(u32)]);
    }

    return dib, .E_NONE;
}

Data_ExpectedValues :: struct {
    length: int,
}

@(private="file")
_bmp_read_data :: proc(reader: io.Reader, dib: bmpfile_dib_info, expected: Data_ExpectedValues) -> ([]u8, BMP_Error) {
    data := make([]u8, dib.width * dib.height + (dib.height * (4 - ((dib.width * 3) % 4)) % 4));
    len, err := io.read(reader, data);
    if len != expected.length {
        delete(data);
        return {}, .E_READ_UNEXPECTED_END_OF_FILE; // ????
    } 
    return data, .E_NONE;
}