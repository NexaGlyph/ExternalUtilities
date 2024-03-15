package image

import "core:image/png"
import "core:mem"
import "core:os"
import "core:io"
import "core:log"

import "../optional"

_4BYTE_MAX_VALUE :: (1 << 31) - 1;
CHUNK_MAX_LENGTH :: _4BYTE_MAX_VALUE;

PNG_Error :: enum {
    /* NO ERROR */
    E_NONE,
    /* INVALID CRITICAL CHUNK: failed to read critical chunk */
    E_READ_CRITICAL,
    /* FAILED TO FIND HEADER CHUNK */
    E_READ_MISSING_IHDR,
    /* FAILED TO FIND PALETTE CHUNK (THIS IS CAN BE SEEN ONLY UNDER CERTAIN CIRCUMSTANCES) */
    /* TO DO: MAKE A FUNCTION THAT WILL RETURN "EXTENDED" INFORMATION ABOUT SUCH ERRORS */
    E_READ_MISSING_PLTE,
    /* FAILED TO FIND END CHUNK */
    E_READ_MISSING_IEND,
    /* INVALID CHUNK SIZE */
    E_READ_CHUNK_SIZE,
    /* INVALID IHDR_Data width, height: width or height size set to 0 */
    E_READ_SIZE,
    /* WHEN A COMPRESSION CODE IS NOT BEING RECOGNIZED */
    E_READ_COMPRESSION_CODE_UNRECOGNIZED,
    /* WHEN A BIT DEPTH IS ASSOCIATED WITH INVALID COLOR_TYPE */
    E_READ_COLOR_TYPE_SUM_INVALID,
    /* WHEN NUMBER OF PALETTE ENTRIES IS NOT ACCURATE 
        (NOTE: THIS IS ONLY RAISED WHEN THE NUM OF PALETTE ENTRIES IS NOT DIVISIBLE BY 3,
            NOT WHEN THE NUMBER OF PALETTE ENTRIES IS NOT ALIGNED, THIS WILL BE IGNORED) 
    */
    E_READ_NUM_PALETTE_ENTRIES,
}

PNG_Schema :: struct { // just a struct of critical chunks
    header: IHDR,
    palette: optional.Optional(PLTE),
    data: IDAT,
    end: IEND,
}

validate_num_of_palette_entries :: proc(using schema: ^PNG_Schema, bit_depth: u8) -> (err: PNG_Error) {
    if optional.get(&palette, optional.NO_PTR).length % 3 == 0 do return .E_NONE;
    return .E_READ_NUM_PALETTE_ENTRIES;
}

validate_color_type_sum :: proc(using schema: ^PNG_Schema) -> (err: PNG_Error) {
    switch header.color_type {
        case 3: // palette HAS TO BE present
            if optional.get_ptr(&palette) == nil do return .E_READ_MISSING_PLTE;
            return .E_NONE;
        case:
            return .E_NONE;
    }
}

ChunkType :: [4]byte; // this should be only ASCII from [A-Z] or [a-z]
IHDR_TYPE :: [4]u8 { 'I', 'H', 'D', 'R' };
PLTE_TYPE :: [4]u8 { 'P', 'L', 'T', 'E' };
IDAT_TYPE :: [4]u8 { 'I', 'D', 'A', 'T' };
IEND_TYPE :: [4]u8 { 'I', 'E', 'N', 'D' };

@(deprecated="This is not correct way to calculate the chunk's length!")
calculate_chunk_length :: #force_inline proc(data_sz: int) -> u32be {
    return u32be(size_of(ChunkType) + data_sz + size_of(u32));
}

CRC_TABLE := [256]u32 {
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832,
    0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
    0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856, 0x646ba8c0, 0xfd62f97a,
    0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
    0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b, 0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
    0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
    0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab,
    0xb6662d3d, 0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01, 0x6b6b51f4,
    0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
    0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074,
    0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
    0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525,
    0x206f85b3, 0xb966d409, 0xce61e49f, 0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
    0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
    0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7, 0xfed41b76,
    0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
    0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c, 0x36034af6,
    0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
    0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7,
    0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
    0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7,
    0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
    0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
    0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9, 0xbdbdf21c, 0xcabac28a, 0x53b39330,
    0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
    0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
};

crc32 :: proc(type: [4]u8, data: []byte) -> u32 {
    crc := u32(0xffffffff);
    for i in 0..<4 do crc = CRC_TABLE[(crc ~ u32(type[i])) & 255] ~ (crc >> 8);
    for i in 0..<len(data) do crc = CRC_TABLE[(crc ~ u32(data[i])) & 255] ~ (crc >> 8);
    return ~crc;
}

Chunk :: struct($T: typeid) {
    length  : u32be,
    type    : ChunkType,
    using data : T,
    crc     : u32,
}

init_chunk :: #force_inline proc(length: u32be, type: ChunkType, data: $T, crc: u32) -> Chunk(T) {
    return {
        length = length,
        type = type,
        data = data,
        crc = crc,
    };
}

/* CHUNK: IHDR */
IHDR :: Chunk(IHDR_Data);
IHDR_NUM_VALID_OCCURRENCES :: 1;

IHDR_Data :: struct {
    width: u32,
    height: u32,
    bit_depth: u8,
    color_type: u8,
    /* "methods" */
    m_compression: u8,
    m_filter: u8,
    m_interlace: u8,
}

Interlace :: enum u8 {
    NoInterlace = 0,
    Adam7 = 1,
}
NO_INTERLACE :: Interlace.NoInterlace;
ADAM7 :: Interlace.Adam7;

CRC_IHDR_Data :: struct {
    width: []u8,
    height: []u8,
    bit_depth: u8,
    color_type: u8,
    m_compression: u8,
    m_filter: u8,
    m_interlace: u8,
}

get_crc_ihdr_data_buffer :: #force_inline proc(data: ^IHDR_Data) -> CRC_IHDR_Data {
    return {
        btranspose_32u(data^.width),
        btranspose_32u(data^.height),
        data^.bit_depth,
        data^.color_type,
        data^.m_compression,
        data^.m_filter,
        data^.m_interlace,
    };
}

get_crc_ihdr_data_array :: #force_inline proc(data: ^CRC_IHDR_Data) -> []u8 {
    return []u8 {
                // 'I', 'H', 'D', 'R',
                data.width[0],
                data.width[1],
                data.width[2],
                data.width[3],
                data.height[0],
                data.height[1],
                data.height[2],
                data.height[3],
                data.bit_depth,
                data.color_type,
                data.m_compression,
                data.m_filter,
                data.m_interlace,
            };
}

IHDR_DataLength :: 2 * size_of(u32) + 5 * size_of(u8);

@(private="file")
init_IHDR :: #force_inline proc(size: ImageSize, img_type: ImageTypeUUID, bit_depth: u8) -> IHDR {
    data := IHDR_Data {
        width = size.x,
        height = size.y,
        bit_depth = bit_depth,
        color_type = img_type == BGR_UUID ? COLOR_TYPE_RGB : COLOR_TYPE_RGBA,
        m_compression = 0,
        m_filter = 0,
        m_interlace = 0,
    };
    crc_data := get_crc_ihdr_data_buffer(&data);
    return init_chunk(
        IHDR_DataLength,
        IHDR_TYPE,
        data,
        crc32(IHDR_TYPE, get_crc_ihdr_data_array(&crc_data)),
    );
}

// sizes
IHDR_WIDTH_MAX  :: _4BYTE_MAX_VALUE;
IHDR_HEIGHT_MAX :: _4BYTE_MAX_VALUE;
// bit depth
BIT_DEPTH_VALID_VALUES :: [5]u8 {
    1, 2, 4, 8, 16,
};
// color type
ColorType :: enum u8 {
    NONE         = 0,
    PALETTE_USED = 1,
    COLOR_USED   = 2,
    ALPHA_USED   = 4,
}
COLOR_TYPE_RGB  :: 2;
COLOR_TYPE_RGBA :: 6;
COLOR_TYPE_VALID_SUMS :: [?]u8 {
    0, 2, 3, 4, 6,
};
/* TO DO: COLOR_TYPE_SUM to BIT_DEPTH validation table */

// m_filter
MFilterType :: enum u8 {
    None    = 0,
    Sub     = 1,
    Up      = 2,
    Average = 3,
    Paeth   = 4,
}
// m_compresssion TO DO

/* CHUNK: PLTE */
PLTE :: Chunk(PLTE_Data);
PLTE_NUM_VALID_OCCURRENCES :: 1;

PaletteEntry :: [3]u8;
PLTE_Data :: struct {
    entries: []PaletteEntry,
}
PLTE_DataLength :: -1; /* >>>NOTE: TO DO */

init_PLTE :: #force_inline proc() -> optional.Optional(PLTE) {
    return init_chunk(0, PLTE_TYPE, optional.init(PLTE), 0);
}

/* CHUNK: IDAT */
IDAT :: Chunk(IDAT_Data);

IDAT_NUM_VALID_OCCURRENCES :: -1; // TO DO
IDAT_Data :: struct {
    compressed_blocks: []IDAT_DataBlock,
}

CRC_IDAT_Data :: struct {
    compressed_blocks: []CRC_IDAT_DataBlock,
}

// CRC_IDAT_DataBlock_conversion :: proc(block: IDAT_DataBlock, block_size: int) -> []u8 {
//     converted_block := make([]u8, block_size);
//     copy(converted_block[0:2], btranspose_16u(block.length));
//     converted_block[3] = block.zlib_header.CMF;
//     converted_block[4] = block.zlib_header.FLG;
//     mem.copy(raw_data(converted_block[5:]), raw_data(block.compressed_data), block_size - RAW_IDAT_DATA_BLOCK_SIZE);
//     copy(converted_block[5 + block_size - RAW_IDAT_DATA_BLOCK_SIZE:], btranspose_32u(block.adler));
//     return converted_block;
// }

// get_crc_idat_data_array :: proc(blocks: []IDAT_DataBlock, compressed_data_len: int) -> []u8 {
//     crc_byte_array := make([]u8, compressed_data_len + len(blocks) * RAW_IDAT_DATA_BLOCK_SIZE);
//     previous := 0;
//     for block, index in blocks {
//         block_size := RAW_IDAT_DATA_BLOCK_SIZE + len(block.compressed_data);
//         converted_block := CRC_IDAT_DataBlock_conversion(block, block_size);
//         copy(crc_byte_array[previous : previous + block_size], converted_block);
//         previous += block_size;
//         delete(converted_block);
//     }
//     return crc_byte_array;
// }

compress8 :: proc(data_to_compress: []BGR8) -> []u8 {
    data := make([]u8, len(data_to_compress) * 3);
    for index in 0..<len(data_to_compress) {
        data[index * 3] = data_to_compress[index].r.data;
        data[index * 3 + 1] = data_to_compress[index].g.data;
        data[index * 3 + 2] = data_to_compress[index].b.data;
    }
    return data;
}

compress16 :: proc(data_to_compress: []BGR16) -> []u8 {
    assert(false, "TO DO: REINTERPRET");
    for bgr in data_to_compress {

    }
    return {};
}

compress32 :: proc(data_to_compress: []BGR32) -> []u8 {
    assert(false, "TO DO: REINTERPRET");
    for bgr in data_to_compress {

    }
    return {};
}

compress :: proc { compress8, compress16, compress32 }

init_IDAT :: proc(data: ^IDAT, data_to_compress: []BGR($PixelDataT)) {
    // IDAT_Data
    compressed_data: []u8 = compress(data_to_compress);
    defer delete(compressed_data);
    if len(compressed_data) > IDAT_DATA_BLOCK_COMPRESSED_DATA_MAX_SIZE {
        num_blocks := (len(compressed_data) + IDAT_DATA_BLOCK_COMPRESSED_DATA_MAX_SIZE - 1) / IDAT_DATA_BLOCK_COMPRESSED_DATA_MAX_SIZE;
        data.compressed_blocks = make([]IDAT_DataBlock, num_blocks);

        for i in 0..<num_blocks {
            start := i * IDAT_DATA_BLOCK_COMPRESSED_DATA_MAX_SIZE;
            end := min((i+1) * IDAT_DATA_BLOCK_COMPRESSED_DATA_MAX_SIZE, len(compressed_data));

            data.compressed_blocks[i].length = u16(end - start);
            data.compressed_blocks[i].compressed_data = compressed_data[start:end];
            data.compressed_blocks[i].zlib_header = ZLIBHDR_DEFAULT;
            data.compressed_blocks[i].adler = 0;
        }
    }
    else {
        data.compressed_blocks = make([]IDAT_DataBlock, 1); 
        data.compressed_blocks[0].length = u16(len(compressed_data));
        data.compressed_blocks[0].compressed_data = make([]u8, len(compressed_data));
        copy(data.compressed_blocks[0].compressed_data, compressed_data);
        // log.errorf("%v", data.compressed_blocks[0].compressed_data);
        data.compressed_blocks[0].zlib_header = ZLIBHDR_DEFAULT;
        data.compressed_blocks[0].adler = 0;
    }
    
    // Chunk data
    data.length = u32be(len(compressed_data));
    data.type = IDAT_TYPE;
    // crc_array := get_crc_idat_data_array(data.compressed_blocks, len(compressed_data))
    // defer delete(crc_array);
    data.crc = crc32(IDAT_TYPE, compressed_data);
}

IDAT_DataBlock :: struct {
    length: u16,
    zlib_header: ZLibHeader,
    compressed_data: []u8,
    adler: u32,
}
RAW_IDAT_DATA_BLOCK_SIZE :: size_of(u16) + 2 * size_of(u8) + size_of(u32); // size of PURE RAW data, ignoring slices 

dump_data_block :: proc(block: ^IDAT_DataBlock) {
    delete(block^.compressed_data);
}

CRC_IDAT_DataBlock :: struct {
    length: []u8,
    zlib_header: CRC_ZlibHeader,
    compressed_data: []u8,
    adler: []u8,
}

IDAT_DATA_BLOCK_COMPRESSED_DATA_MAX_SIZE :: (1 << 16) - 1;

CMF             :: u8; // Compression method and flags
CMF_CM_MASK     :: 0b0000_0111; // three bits of the first byte
CMF_CINFO_MASK  :: 0b0111_0000; // three bits of the second byte
CMF_CINFO_SHIFT :: 4; 

FLG             :: u8;
FLG_CHECK_MASK  :: 0b0000_1111; // four  bits of the first byte
FLG_DICT_MASK   :: 0b0001_0000; // one   bit of the second byte
FLG_LEVEL_MASK  :: 0b1110_0000; // three bits of the second byte
FLG_DICT_SHIFT  :: 5;
FLG_LEVEL_SHIFT :: 6;

ZLibHeader :: struct {
    CMF: CMF,
    FLG: FLG,
}

CRC_ZlibHeader :: ZLibHeader;

ZLIBHDR_DEFAULT :: ZLibHeader {
    CMF = 0b0111_0000,
    FLG = 0b0000_0000,
}

init_zlibhdr :: #force_inline proc(cm: u8, cinfo: u8, fcheck: u8, fdict: u8, flevel: u8) -> ZLibHeader {
    return {
        CMF = (cm & CMF_CM_MASK) | ((cinfo << CMF_CINFO_SHIFT) & CMF_CINFO_MASK),
        FLG = (fcheck & FLG_CHECK_MASK) | ((fdict << FLG_DICT_SHIFT) & FLG_DICT_MASK) | ((flevel << FLG_LEVEL_SHIFT) & FLG_LEVEL_MASK),
    };
}

/* CHUNK: IEND */
IEND :: Chunk(IEND_Data);

IEND_NUM_VALID_OCCURRENCES :: 1;
IEND_Data :: struct {}
IEND_DataLength :: size_of(IEND_Data);

init_IEND :: #force_inline proc() -> IEND {
    return init_chunk(IEND_DataLength, IEND_TYPE, IEND_Data{}, crc32(IEND_TYPE, {}));
}

/* READ */
png_read :: proc() {}

png_read_chunk :: proc() {}

/* WRITE */
png_write :: proc { png_write_bgr8, png_write_bgr16, png_write_bgr32 }

png_write_bgr8  :: proc(using img: ^ImageBGR8, file_path: string) {
    png := PNG_Schema{};
    defer {
        for block in &png.data.compressed_blocks do dump_data_block(&block);
        delete(png.data.compressed_blocks);
    }
   
    log.infof("[PNG-WRITE-BEGIN]");

    png.header  = init_IHDR(size, BGR_UUID, 8);
    log.infof("[PNG-WRITE]: HEADER CREATED!");
    png.palette = init_PLTE();
    log.infof("[PNG-WRITE]: PALATTE CREATED!");
    init_IDAT(&png.data, data);
    log.infof("[PNG-WRITE]: DATA CREATED!");
    png.end     = init_IEND();
    log.infof("[PNG-WRITE]: END CREATED!");

    handle, ok := os.open(file_path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC);
    defer os.close(handle);

    if ok != os.ERROR_NONE {
        log.errorf("%v", ok);
        assert(false, "Failed to open file [png] for writing");
    }
    
    _png_write(&png, { os.stream_from_handle(handle) });
    
    log.infof("[PNG-WRITE-END]");
}

png_write_bgr16 :: proc(using img: ^ImageBGR16, file_path: string) {
    assert(false, "TO DO!");
}
png_write_bgr32 :: proc(using img: ^ImageBGR32, file_path: string) {
    assert(false, "TO DO!");
}

@(private="file")
_png_write :: proc(using schema: ^PNG_Schema, writer: io.Writer) {
    png_write_header(writer);
    png_write_chunk(&header, writer);
    // png_write_chunk(optional.get(&palette), writer);
    png_write_chunk(&data, writer);
    png_write_chunk(&end, writer);
}

PNG_HEADER :: []u8 {
    137, 80, 78, 71, 13, 10, 26, 10,
}

png_write_header :: #force_inline proc(writer: io.Writer) {
    _write_file_safe(writer, PNG_HEADER);
}

png_write_chunk :: proc(using chunk: ^Chunk($T), writer: io.Writer) {
    _write_file_safe(writer, _transpose_chunk_length(length));
    _write_file_safe(writer, type[:]);
    png_write_chunk_data(writer, &data);
    _write_file_safe(writer, btranspose_32u(crc)); 
}

png_write_chunk_data :: proc { png_write_header_chunk_data, png_write_palette_chunk_data, png_write_data_chunk_data, png_write_end_chunk_data }

png_write_header_chunk_data  :: proc(writer: io.Writer, header: ^IHDR_Data) {
    _write_file_safe(writer, btranspose_32u(header^.width));
    _write_file_safe(writer, btranspose_32u(header^.height));
    _write_file_safe(writer, { header^.bit_depth, header^.color_type, header^.m_compression, header^.m_filter, header^.m_interlace });
}

png_write_palette_chunk_data :: proc(writer: io.Writer, palette: ^PLTE_Data) {
    entries: []u8 = make([]u8, len(palette^.entries) * len(PaletteEntry));
    defer delete(entries);
    mem.copy(raw_data(entries), raw_data(palette^.entries), len(entries));
    log.warnf("MAKE SURE THAT THIS COPY IS SUCCESSFULL");
    _write_file_safe(writer, entries);
}

png_write_data_chunk_data    :: proc(writer: io.Writer, data: ^IDAT_Data) {
    for block in data^.compressed_blocks {
        _write_file_safe(writer, btranspose_16u(block.length));
        // log.infof("%v", btranspose_16u(block.length));
        _write_file_safe(writer, { block.zlib_header.CMF, block.zlib_header.FLG });
        // log.infof("%v .... %v", block.zlib_header.CMF, block.zlib_header.FLG);
        _write_file_safe(writer, block.compressed_data);
        log.infof("%v", block.compressed_data);
        log.infof("%v", len(block.compressed_data));
        _write_file_safe(writer, btranspose_32u(block.adler));
        // log.infof("%v", btranspose_32u(block.adler));
    }
}

@(disabled=true) // this basically does nothing, so mark it as disabled
png_write_end_chunk_data     :: proc(writer: io.Writer, end: ^IEND_Data) {}

@(private="file")
/*>>>NOTE: MAKE THIS WRITER STRATEGY FOR ALL THE IMAGE TYPES */
_write_file_safe :: proc(writer: io.Writer, data: []byte) {
    size, err := io.write(writer, data);
    if err != .None {
        log.errorf("%v", err);
        assert(false, "write file failed!");
    }
    assert(size == len(data), "Failed to write whole buffer!");
}

@(private="file")
_transpose_chunk_length :: proc(value: u32be) -> []u8 {
    return {
        cast(u8)(value >> 24),
        cast(u8)(value >> 16),
        cast(u8)(value >> 8),
        cast(u8)(value),
    };
}