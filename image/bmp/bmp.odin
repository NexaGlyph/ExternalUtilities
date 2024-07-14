package bmp

import "core:io"
import "core:os"
import "core:mem"
import "core:log"
import "core:strings"
import "core:math"

import "../../image"
import "../utils"

/* ALL OF THE OTHER ERRORS (LIKE IN WRITING) ARE USUALLY CAUGHT WITH THE UITLITY FUNCTIONS AND ARE ASSERTED */
BMP_ReadError :: enum u8 {
    E_NONE = 0,

    E_READ_FILE,
    E_READ_UNRECOGNIZED_FILE_SIZE,
    E_READ_INVALID_FILE_FORMAT,
    E_READ_UNSUPPORTED_BIT_DEPTH,
    E_READ_UNSUPPORTED_COMPRESSION_METHOD,
    E_READ_INSUFFICIENT_MEMORY,
    E_READ_CORRUPTED_DATA,
    E_READ_UNEXPECTED_END_OF_FILE,
    E_READ_INCORRECT_IMAGE_TYPE,
}

BMP_WriteError :: enum u8 {
    E_NONE = 0,

    E_WRITE_FAILED,
    E_WRITE_INSUFFICIENT_DATA,
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

BMP_PaletteEntry :: utils.PaletteEntry;
BMP_Palette      :: utils.Palette; 

BMP_Palette256   :: utils.Palette256;
BMP_Palette64    :: utils.Palette64;
BMP_Palette16    :: utils.Palette16;
BMP_Palette2     :: utils.Palette2;

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
        file_size  = BMP_OFFSET + BITMAP_DATA_SIZE(auto_cast size.x, auto_cast size.y),
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
        num_colors = bit_depth > 8 ? 0 : u32(math.pow(2, f32(bit_depth))),
        num_important_colors = 0,
    };
}

init_palette_gradient :: #force_inline proc($N: int) -> BMP_Palette(N) {
    gradient_colors: [N]BMP_PaletteEntry = {};

    for i in 0..=u8(N - 1) do gradient_colors[i] = { i, i, i, 0, };

    return BMP_Palette(N){ gradient_colors };
}

/* BMP WRITE */
@(require_results)
bmp_write_auto :: proc(using img: ^image.RawImage, file_path: string) -> BMP_WriteError {
    handle := _bmp_write_begin(file_path);
    writer: io.Writer = os.stream_from_handle(handle);
    defer os.close(handle);
    defer io.destroy(writer);

    _bmp_write_magic(writer);
    _bmp_write_header(writer, init_header(size));
    bit_depth := u16(0);
    switch (info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK) >> 4 {
        case image.UINT8_UUID..=image.SINT8_UUID:
            bit_depth = 24;
        case image.UINT16_UUID..=image.SINT16_UUID:
            fallthrough;
        case image.UINT32_UUID..=image.SINT32_UUID:
            fallthrough;
        case:
            assert(false);
    }
    _bmp_write_dib(writer, init_dib(size, bit_depth));

    if info & image.IMAGE_INFO_IMAGE_TYPE_UUID_MASK != image.BGR_UUID {
        assert(false, "Not yet supported!");
    }
    bmp_array := make([]u8, 3 * size.x * size.y);
    log.infof("AUTO_SIZE :: %v", 3 * size.x * size.y);
    assert(mem.copy(raw_data(bmp_array), data, int(3 * size.x * size.y)) != nil, "Failed to copy raw buffer into temp memory!");
    defer delete(bmp_array);
    return _bmp_write_data(writer, size.x, size.y, cast(u32)bit_depth/8, bmp_array[:]);
}

bmp_write_bgr :: proc(using img: ^image.Image2(image.BGR($PixelDataT)), file_path: string) -> (err: BMP_WriteError) {
    bit_depth: u16 = 0;
    switch (info & image.IMAGE_INFO_PIXEL_TYPE_UUID_MASK) >> 4 {
        case image.UINT8_UUID:
            bit_depth = 24;
            break;
        case image.UINT16_UUID: // these two (16, 32) will have to be ignored and casted to BGR8
            assert(size_of(PixelDataT) == 2, "invalid pixel type for UINT16_UUID flag!");
            img_refactored := image.reinterpret_image_bgr(image.ImageBGR8, image.Image2(image.BGR(PixelDataT)), img);
            defer image.dump_image2(&img_refactored);
            return bmp_write_bgr(&img_refactored, file_path);
        case image.UINT32_UUID:
            assert(size_of(PixelDataT) == 4, "invalid pixel type for UINT32_UUID flag!");
            img_refactored := image.reinterpret_image_bgr(image.ImageBGR8, image.Image2(image.BGR(PixelDataT)), img);
            defer image.dump_image2(&img_refactored);
            return bmp_write_bgr(&img_refactored, file_path);
        case:
            assert(false, "Invalid PIXEL_TYPE_UUID!");
    }

    handle := _bmp_write_begin(file_path);
    writer: io.Writer = os.stream_from_handle(handle);
    defer os.close(handle);
    defer io.destroy(writer);
   
    _bmp_write_magic(writer);
    _bmp_write_header(writer, init_header(size));
    _bmp_write_dib(writer, init_dib(size, bit_depth));
    bmp_array := _bmp_data_convert8(data, size);
    return _bmp_write_data(writer, size.x, size.y, cast(u32)bit_depth / 8, bmp_array);
}

/*
    This function can be used for "extended" featured writing, e.g. using specific BMP_Palette 
*/
bmp_write_bgr_palette :: proc(using img: ^image.ImageBGR8, palette: BMP_Palette($N), file_path: string) {
    handle := _bmp_write_begin(file_path);
    writer: io.Writer = os.stream_from_handle(handle);
    defer os.close(handle);
    defer io.destroy(writer);
   
    _bmp_write_magic(writer);
    _bmp_write_header(writer, init_header(size));
    _bmp_write_dib(writer, init_dib(size, N)); 
    // palette
    utils.write_file_safe(writer, palette.entries);

    bmp_array := _bmp_data_convert8(data, size);
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
        assert(false, "Failed to open file [bmp] for writing");
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
//>>>NOTE: the $PixelDataT is here for convenience since we are working with raw_union(s), type conversions/deductions are not so easily procured
_bmp_data_convert8 :: #force_inline proc(data_before: []image.BGR($PixelDataT), size: image.ImageSize) -> []u8 {
    // this cannot work because the BGR has to be padded by extra byte (this transmute then fails...)
    // return transmute([]u8)mem.Raw_Slice {
    //     data = raw_data(data_before),
    //     len = int(size.x * size.y * 3),
    // }
    byte_array := make([]u8, size.x * size.y * 3);
    for bgr, index in data_before {
        byte_array[3 * index + 0] = bgr.r.data;
        byte_array[3 * index + 1] = bgr.g.data;
        byte_array[3 * index + 2] = bgr.b.data;
    }
    return byte_array;
}

@(private="file")
@(deprecated="in this package ImageBGR16 are not directly supported, they are reinterpretted to ImageBGR8")
_bmp_data_convert16 :: #force_inline proc(data_before: []image.BGR16, size: image.ImageSize) -> []u8 {    
    #no_bounds_check data_after := make([]u8, len(data_before) * 3 * size_of(u16));

    pos: u32;
    bgr: image.BGR16;
    _2byte_array: utils._2BYTES; 
    for i in 0..<size.y*size.x {
        bgr = data_before[i];
        pos = i * 6;
        {
            _2byte_array = utils.btranspose_16u(bgr.r.data);
            data_after[pos + 0] = _2byte_array[0];
            data_after[pos + 1] = _2byte_array[1];
        }
        {
            _2byte_array = utils.btranspose_16u(bgr.g.data);
            data_after[pos + 2] = _2byte_array[0];
            data_after[pos + 3] = _2byte_array[1];
        }
        {
            _2byte_array = utils.btranspose_16u(bgr.b.data);
            data_after[pos + 4] = _2byte_array[0];
            data_after[pos + 5] = _2byte_array[1];
        }
    }

    return data_after;
}

@(private="file")
@(deprecated="in this package ImageBGR32 are not directly supported, they are reinterpretted to ImageBGR8")
_bmp_data_convert32 :: #force_inline proc(data_before: []image.BGR32, size: image.ImageSize) -> []u8 {    
    #no_bounds_check data_after := make([]u8, len(data_before) * 3 * size_of(u32));

    pos: u32;
    bgr: image.BGR32;
    _4byte_array: utils._4BYTES;
    for i in 0..<size.y*size.y {
        bgr = data_before[i];
        pos = 12 * i;
        {
            _4byte_array = utils.btranspose_32u(bgr.r.data);
            data_after[pos + 0] = _4byte_array[0];
            data_after[pos + 1] = _4byte_array[1];
            data_after[pos + 2] = _4byte_array[2];
            data_after[pos + 3] = _4byte_array[3];
        }
        {
            _4byte_array = utils.btranspose_32u(bgr.g.data);
            data_after[pos + 4] = _4byte_array[0];
            data_after[pos + 5] = _4byte_array[1];
            data_after[pos + 6] = _4byte_array[2];
            data_after[pos + 7] = _4byte_array[3];
        }
        {
            _4byte_array = utils.btranspose_32u(bgr.b.data);
            data_after[pos + 8]  = _4byte_array[0];
            data_after[pos + 9]  = _4byte_array[1];
            data_after[pos + 10] = _4byte_array[2];
            data_after[pos + 11] = _4byte_array[3];
        }
    }

    return data_after;
}

@(private="file")
@(require_results)
_bmp_write_data :: #force_inline proc(writer: io.Writer, width: u32, height: u32, bytes_per_pixel: u32, data: []u8) -> BMP_WriteError {
    row_size_with_padding := int((width * bytes_per_pixel + 3) / 4) * 4;
    row_size_without_padding := width * bytes_per_pixel;

    row_buffer := make([]u8, row_size_with_padding);
    defer delete(row_buffer);

    for i in 0..<height {
        assert(copy_slice(row_buffer, data[i * row_size_without_padding : (i + 1) * row_size_without_padding]) == row_size_with_padding);

        if row_size_with_padding > int(row_size_without_padding) do mem.zero_slice(row_buffer[row_size_without_padding:]);

        len, err := io.write(writer, row_buffer);
        if len != row_size_with_padding do return .E_WRITE_INSUFFICIENT_DATA;
        if err != .None {
            log.errorf("%v", err);
            return .E_WRITE_FAILED;
        }
    }

    return .E_NONE;
}

@(private="file")
BITMAP_DATA_SIZE :: #force_inline proc(width: i32, height: i32) -> u32 {
    return u32(((width * 3) + ((width * 3) % 4)) * height);
}

/* BMP READ */
@(require_results)
bmp_read_bgr_auto :: proc(file_path: string) -> (img: image.RawImage, err: BMP_ReadError) {
    handle, ok := os.open(file_path, os.O_RDONLY);
    defer os.close(handle);

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        return {}, .E_READ_FILE;
    }
    
    reader: io.Reader = os.stream_from_handle(handle);

    _bmp_read_magic(reader) or_return;
    header  := _bmp_read_header(reader, Header_ExpectedValues { BMP_OFFSET }) or_return;
    dib     := _bmp_read_dib(reader, DIB_ExpectedValues { 24 }) or_return;

    img.size = image.IMAGE_SIZE(dib.width, dib.height);
    img.info = image.BGR_UUID;

    possible_palette_size := 0;
    switch dib.bits_per_pixel {
        case 1: // for these "lower" bits, we have to transmute the data as if it were 8 bit but still can return the data
            img.info |= (image.UINT8_UUID << 4);
            palette := _bmp_read_palette(reader, 2) or_return;
            possible_palette_size = 2 * 4;
        case 2:
            img.info |= (image.UINT8_UUID << 4);
            palette := _bmp_read_palette(reader, 4) or_return;
            possible_palette_size = 4 * 4;
        case 4:
            img.info |= (image.UINT8_UUID << 4);
            palette := _bmp_read_palette(reader, 16) or_return;
            possible_palette_size = 16 * 4;
        case 8:
            img.info |= (image.UINT8_UUID << 4);
            palette := _bmp_read_palette(reader, 256) or_return;
            possible_palette_size = 256 * 4;
        case 16:
            assert(false, "right now ambigous since there are vast possibilities of bit depth color ordering...");
            /* R5G6B5; A1R5G5B5; X1R5G5B5 */
        case 24:
            img.info |= (image.UINT8_UUID << 4);
        case 32:
            return {}, .E_READ_INCORRECT_IMAGE_TYPE; // this is RGBA, not BGR
        case:
            log.errorf("Unsupported bit depth: %v", dib.bits_per_pixel);
            return {}, .E_READ_UNSUPPORTED_BIT_DEPTH;
    }

    /*>>>NOTE: SHOULD CHECK CASTING LIKE THIS EVERYWHERE!!! (i32 -> u32) is invalid*/
    data    := _bmp_read_data(reader, auto_cast dib.width, auto_cast dib.height, auto_cast dib.bits_per_pixel / 8, Data_ExpectedValues { 
        auto_cast BITMAP_DATA_SIZE(dib.width, dib.height),
     }) or_return;
    img.data = raw_data(data);
    return img, .E_NONE;
}

@(require_results)
bmp_read_bgr8 :: proc(file_path: string) -> (img: image.ImageBGR8, err: BMP_ReadError) {
    handle, ok := os.open(file_path, os.O_RDONLY);
    defer os.close(handle);

    if ok != os.ERROR_NONE do return {}, .E_READ_FILE;
    
    reader: io.Reader = os.stream_from_handle(handle);

    _bmp_read_magic(reader) or_return;
    header := _bmp_read_header(reader, Header_ExpectedValues { BMP_OFFSET }) or_return;
    dib    := _bmp_read_dib(reader, DIB_ExpectedValues { 24 }) or_return;
    data   := _bmp_read_data(reader, auto_cast dib.width, auto_cast dib.height, auto_cast dib.bits_per_pixel/8, Data_ExpectedValues { auto_cast BITMAP_DATA_SIZE(dib.width, dib.height) }) or_return;

    img.data = make([]image.BGR8, dib.width * dib.height);
    img.info = image.BGR_UUID | (image.UINT8_UUID << 4);
    img.size = image.IMAGE_SIZE(dib.width, dib.height);
    copy_data_into_img :: proc(data: []u8, img: []image.BGR8) {
        for i := 0; i < len(img); i += 1 {
            img[i].r.data = data[i * 3 + 0];
            img[i].g.data = data[i * 3 + 1];
            img[i].b.data = data[i * 3 + 2];
        }
    }
    copy_data_into_img(data[:], img.data[:]);

    return img, .E_NONE;
}

bmp_read_bgr16 :: proc() -> image.ImageBGR16 {
    return {};
}

bmp_read_bgr32 :: proc() -> image.ImageBGR32 {
    return {};
}

validate_magic :: #force_inline proc "fastcall" (magic: [2]u8) -> BMP_ReadError {
    if magic[0] != 'B' || magic[1] != 'M' do return .E_READ_INVALID_FILE_FORMAT;
    return .E_NONE;
}

@(private="file")
_bmp_read_magic :: proc(reader: io.Reader) -> BMP_ReadError {
    magic := [2]u8{};
    io.read(reader, magic[:]);
    return validate_magic(magic);
}

Header_ExpectedValues :: struct {
    bmp_offset: u32,
}

@(private="file")
_bmp_read_header :: proc(reader: io.Reader, expected: Header_ExpectedValues) -> (bmpfile_header, BMP_ReadError) {
    header_binary := make([]u8, size_of(bmpfile_header));
    defer delete(header_binary);

    io.read(reader, header_binary);
    header := bmpfile_header{};
    {
        next := 0;
        header.file_size  = utils.u32_le_transpose(header_binary[next:next + size_of(u32)]);
        if header.file_size == 0 do return {}, .E_READ_UNRECOGNIZED_FILE_SIZE;
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
_bmp_read_dib :: proc(reader: io.Reader, expected: DIB_ExpectedValues) -> (bmpfile_dib_info, BMP_ReadError) {
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

@(private="file")
_bmp_read_palette :: proc(reader: io.Reader, $N: int) -> ([N]BMP_PaletteEntry, BMP_ReadError) {
    data: [N * 4]u8 = {}; 
    len, err := io.read(reader, data[:]);
    if len != N * 4 do return {}, .E_READ_UNEXPECTED_END_OF_FILE;
    if err != .None {
        log.errorf("%v", err);
        return {}, .E_READ_CORRUPTED_DATA;
    }
    return transmute([N][4]u8)data, .E_NONE;
}

Data_ExpectedValues :: struct {
    length: int,
}

@(private="file")
_bmp_read_data :: proc(reader: io.Reader, width: u32, height: u32, bytes_per_pixel: u32, expected: Data_ExpectedValues) -> ([]u8, BMP_ReadError) {

    row_size_with_padding := int((width * bytes_per_pixel + 3) / 4) * 4;
    row_size_without_padding := width * bytes_per_pixel;

    row_buffer := make([]u8, row_size_with_padding);
    final_data := make([]u8, row_size_without_padding * height);
    defer delete(row_buffer);

    for i in 0..<height {
        len, err := io.read(reader, row_buffer);
        if len != row_size_with_padding {
            delete(final_data);
            return {}, .E_READ_UNEXPECTED_END_OF_FILE;
        } 
        if err != .None {
            log.errorf("%v", err);
            delete(final_data);
            return {}, .E_READ_CORRUPTED_DATA;
        }
        copy_slice(final_data[i * row_size_without_padding:(i+1)*row_size_without_padding], row_buffer[:row_size_without_padding]);
    }
    return final_data, .E_NONE;
}