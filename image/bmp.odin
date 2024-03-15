package image

import "core:io"
import "core:os"
import "core:log"

/* ALL OF THE OTHER ERRORS (LIKE IN WRITING) ARE USUALLY CAUGHT WITH THE UITLITY FUNCTIONS AND ARE ASSERTED */
BMP_Error :: enum {
    E_NONE,
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
BMP_OFFSET :: size_of(bmpfile_magic) + size_of(bmpfile_header) + size_of(bmpfile_dib_info);

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

init_header :: proc(size: ImageSize) -> bmpfile_header {
    return {
        file_size  = BMP_OFFSET + size.x * size.y * 3,
        creator1   = u16(0),
        creator2   = u16(0),
        bmp_offset = BMP_OFFSET, 
    };
}

init_dib :: proc(size: ImageSize, bit_depth: u16) -> bmpfile_dib_info {
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
@(private="file")
_bmp_write_begin :: proc(file_path: string) -> os.Handle {
    handle, ok := os.open(file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file [png] for writing");
    }

    return handle;
}

bmp_write_bgr :: proc(using img: ^Image2(BGR($PixelDataT)), file_path: string) {
    handle := _bmp_write_begin(file_path);
    writer := io.Writer { os.stream_from_handle(handle) };
    defer os.close(handle);
    defer io.destroy(writer);
   
    _bmp_write_magic(writer);
    _bmp_write_header(writer, init_header(size));
    _bmp_write_dib(writer, init_dib(size, 8 * size_of(PixelDataT)));
    bmp_array := _bmp_data_convert(data, size);
    _bmp_write_data(writer, bmp_array);
}

@(private="file")
_bmp_write_magic :: #force_inline proc(writer: io.Writer) {
    write_file_writer(writer, { 'B', 'M' });
}

@(private="file")
_bmp_write_header :: #force_inline proc(writer: io.Writer, header: bmpfile_header) {
    write_file_writer(writer, btranspose_32u_le(header.file_size));
    write_file_writer(writer, btranspose_16u_le(header.creator1));
    write_file_writer(writer, btranspose_16u_le(header.creator2));
    write_file_writer(writer, btranspose_32u_le(header.bmp_offset));
}

@(private="file")
_bmp_write_dib :: #force_inline proc(writer: io.Writer, dib: bmpfile_dib_info) {
    write_file_writer(writer, btranspose_32u_le(dib.header_size));
    write_file_writer(writer, btranspose_32i_le(dib.width));
    write_file_writer(writer, btranspose_32i_le(dib.height));
    write_file_writer(writer, btranspose_16u_le(dib.num_planes));
    write_file_writer(writer, btranspose_16u_le(dib.bits_per_pixel));
    write_file_writer(writer, btranspose_32u_le(dib.compression));
    write_file_writer(writer, btranspose_32u_le(dib.bmp_byte_size));
    write_file_writer(writer, btranspose_32i_le(dib.hres));
    write_file_writer(writer, btranspose_32i_le(dib.vres));
    write_file_writer(writer, btranspose_32u_le(dib.num_colors));
    write_file_writer(writer, btranspose_32u_le(dib.num_important_colors));
}

@(private="file")
_bmp_data_convert8 :: #force_inline proc(data_before: []BGR8, size: ImageSize) -> []u8 {
    #no_bounds_check data_after := make([]u8, len(data_before) * 4);

    for y in 0..<size.y {
        for x in 0..<size.x {
            bgr := data_before[y * size.x + x];
            data_after[(y*size.x + x)*4 + 0] = bgr.r.data;
            data_after[(y*size.x + x)*4 + 1] = bgr.g.data;
            data_after[(y*size.x + x)*4 + 2] = bgr.b.data;
            data_after[(y*size.x + x)*4 + 3] = 0;
        }
    }

    return data_after;
}

@(private="file")
_bmp_data_convert16 :: #force_inline proc(data_before: []BGR16, size: ImageSize) -> []u8 {    
    #no_bounds_check data_after := make([]u8, len(data_before) * 4 * size_of(u16));

    for y in 0..<size.y {
        for x in 0..<size.x {
            pos := y * size.x + x;
            bgr := data_before[pos];
            {
                r := btranspose_16u(bgr.r.data);
                data_after[pos * 4 + 0] = r[0];
                data_after[pos * 4 + 1] = r[1];
            }
            {
                g := btranspose_16u(bgr.g.data);
                data_after[pos * 4 + 2] = g[0];
                data_after[pos * 4 + 3] = g[1];
            }
            {
                b := btranspose_16u(bgr.b.data);
                data_after[pos * 4 + 4] = b[0];
                data_after[pos * 4 + 5] = b[1];
            }
            {
                x := btranspose_16u(bgr.x.data);
                data_after[pos * 4 + 6] = x[0];
                data_after[pos * 4 + 7] = x[1];
            }
        }
    }

    return data_after;
}

@(private="file")
_bmp_data_convert32 :: #force_inline proc(data_before: []BGR32, size: ImageSize) -> []u8 {    
    #no_bounds_check data_after := make([]u8, len(data_before) * 4 * size_of(u32));

    for y in 0..<size.y {
        for x in 0..<size.x {
            pos := y * size.x + x;
            bgr := data_before[pos];
            {
                r := btranspose_32u(bgr.r.data);
                data_after[pos * 4 + 0] = r[0];
                data_after[pos * 4 + 1] = r[1];
                data_after[pos * 4 + 2] = r[2];
                data_after[pos * 4 + 3] = r[3];
            }
            {
                g := btranspose_32u(bgr.g.data);
                data_after[pos * 4 + 4] = g[0];
                data_after[pos * 4 + 5] = g[1];
                data_after[pos * 4 + 6] = g[0];
                data_after[pos * 4 + 7] = g[1];
            }
            {
                b := btranspose_32u(bgr.b.data);
                data_after[pos * 4 + 8]  = b[0];
                data_after[pos * 4 + 9]  = b[1];
                data_after[pos * 4 + 10] = b[2];
                data_after[pos * 4 + 11] = b[3];
            }
            {
                x := btranspose_32u(bgr.x.data);
                data_after[pos * 4 + 12] = x[0];
                data_after[pos * 4 + 13] = x[1];
                data_after[pos * 4 + 14] = x[2];
                data_after[pos * 4 + 15] = x[3];
            }
        }
    }

    return data_after;
}

@(private="file")
_bmp_data_convert :: proc { _bmp_data_convert8, _bmp_data_convert16, _bmp_data_convert32 }

@(private="file")
_bmp_write_data :: #force_inline proc(writer: io.Writer, data: []u8) {
    write_file_writer(writer, data);
}

bmp_write :: proc { bmp_write_bgr }

/* BMP READ */
bmp_read_bgr_auto :: proc() -> RawImage {
    return {};
}

bmp_read_bgr8 :: proc(file_path: string) -> (ImageBGR8, BMP_Error) {
    handle, ok := os.open(file_path, os.O_RDONLY);
    defer os.close(handle);

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file [png] for writing");
    }
    
    reader := io.Reader{ os.stream_from_handle(handle) };
   
    header: bmpfile_header;
    dib: bmpfile_dib_info;
    data: []u8;

    err := _bmp_read_magic(reader);
    if err != .E_NONE do return {}, err;
    err, header = _bmp_read_header(reader);
    if err != .E_NONE do return {}, err;
    err, dib = _bmp_read_dib(reader);
    if err != .E_NONE do return {}, err;
    err, data = _bmp_read_data(reader, dib);
    return {}, .E_NONE;
}

bmp_read_bgr16 :: proc() -> ImageBGR16 {
    return {};
}

bmp_read_bgr32 :: proc() -> ImageBGR32 {
    return {};
}

validate_magic :: proc(magic: [2]u8) -> BMP_Error {
    if magic[0] != 'B' || magic[1] != 'M' do return .E_READ_INVALID_FILE_FORMAT;
    return .E_NONE;
}

_bmp_read_magic :: proc(reader: io.Reader) -> BMP_Error {
    magic := [2]u8{};
    io.read(reader, magic[:]);
    return validate_magic(magic);
}

_bmp_read_header :: proc(reader: io.Reader) -> (BMP_Error, bmpfile_header) {
    header_binary := make([]u8, size_of(bmpfile_header));
    defer delete(header_binary);

    io.read(reader, header_binary);
    header := bmpfile_header{};
    {
        next := 0;
        header.file_size  = u32_le_transpose(header_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        header.creator1   = u16_le_transpose(header_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        header.creator2   = u16_le_transpose(header_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        header.bmp_offset = u32_le_transpose(header_binary[next:next + size_of(u32)]);
    }

    return .E_NONE, header; // for now, no error checking
}

_bmp_read_dib :: proc(reader: io.Reader) -> (BMP_Error, bmpfile_dib_info) {
    dib_binary := make([]u8, size_of(bmpfile_dib_info));
    defer delete(dib_binary);

    io.read(reader, dib_binary);
    dib := bmpfile_dib_info{};
    {
        next := 0;
        // header size
        dib.header_size = u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // width
        dib.width   = i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // height
        dib.height = i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // number of planes
        dib.num_planes = u16_le_transpose(dib_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        // bit depth
        dib.bits_per_pixel = u16_le_transpose(dib_binary[next:next + size_of(u16)]);
        next += size_of(u16);
        // compression
        dib.compression = u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // byte size
        dib.bmp_byte_size = u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // hres
        dib.hres = i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // vres
        dib.vres = i32_le_transpose(dib_binary[next:next + size_of(i32)]);
        next += size_of(i32);
        // palette
        dib.num_colors = u32_le_transpose(dib_binary[next:next + size_of(u32)]);
        next += size_of(u32);
        // important colors
        dib.num_important_colors = u32_le_transpose(dib_binary[next:next + size_of(u32)]);
    }

    return .E_NONE, dib;
}

_bmp_read_data :: proc(reader: io.Reader, dib: bmpfile_dib_info) -> (BMP_Error, []u8) {
    data := make([]u8, dib.width * dib.height + (dib.height * (4 - ((dib.width * 3) % 4)) % 4));
    io.read(reader, data);
    return .E_NONE, data;
}