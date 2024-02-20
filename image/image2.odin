package image

import "core:mem"
import "core:math/rand"

/* ONE PIXEL VALUE */
PixelData8 :: struct #raw_union {
    data8: u8,
    data8s: i8,
    _data: u8,
}

PixelData16 :: struct #raw_union {
    data16: u16,
    data16s: i16,
    _data: u16,
}

PixelData32 :: struct #raw_union {
    data32: u32,
    data32s: i32,
    _data: u32,
}

/* BGRX PIXEL (FOR CONVENIENCE THE BGR IS PADDED BY THE 'X') */
BGR :: struct($PixelDataT: typeid) #packed {
    b, g, r, x: PixelDataT,
}

BGR8  :: BGR(PixelData8);
BGR16 :: BGR(PixelData16);
BGR32 :: BGR(PixelData32);

/* RGBA PIXEL */
RGBA :: struct($PixelDataT: typeid) #packed {
    r, g, b, a: PixelDataT,
}

RGBA8  :: RGBA(PixelData8);
RGBA16 :: RGBA(PixelData16);
RGBA32 :: RGBA(PixelData32);

/* PIXEL IMAGE */
@(private="package")
Image2 :: struct($PixelType: typeid) {
    size: ImageSize,
    data: []PixelType,
    info: ImageInfoUUID,
}

/* BGR(X) IMAGE */
ImageBGR8  :: Image2(BGR8);
ImageBGR16 :: Image2(BGR16);
ImageBGR32 :: Image2(BGR32);

/* RGBA IMAGE */
ImageRGBA8  :: Image2(RGBA8);
ImageRGBA16 :: Image2(RGBA16);
ImageRGBA32 :: Image2(RGBA32);

/* PIXEL DATA BIT MAX VALUES */
IPIXEL_DATA8_MAX       :: (0x7f)
IPIXEL_DATA16_MAX      :: (0x7fff)
IPIXEL_DATA32_MAX      :: (0x7fffffff)
IPIXEL_DATA64_MAX      :: (0x7fffffffffffffff)

UPIXEL_DATA8_MAX      :: (0xff)
UPIXEL_DATA16_MAX     :: (0xffff)
UPIXEL_DATA32_MAX     :: (0xffffffff)
UPIXEL_DATA64_MAX     :: (0xffffffffffffffff)

/* PIXEL DATA BIT RANDOM GENERATION */
/* 8 BITS */
generate_random_pixel_data_ubgr8 :: #force_inline proc() -> BGR8 {
    return BGR8 {
        b = PixelData8 { data8 = cast(u8)(rand.float32() * UPIXEL_DATA8_MAX) },
        g = PixelData8 { data8 = cast(u8)(rand.float32() * UPIXEL_DATA8_MAX) },
        r = PixelData8 { data8 = cast(u8)(rand.float32() * UPIXEL_DATA8_MAX) },
        x = PixelData8 { data8 = 0 },
    }
}
/* SIGNED 8 BITS */
generate_random_pixel_data_sbgr8 :: #force_inline proc() -> BGR8 {
    return BGR8 {
        b = PixelData8 { data8s = cast(i8)(rand.float32() * IPIXEL_DATA8_MAX) },
        g = PixelData8 { data8s = cast(i8)(rand.float32() * IPIXEL_DATA8_MAX) },
        r = PixelData8 { data8s = cast(i8)(rand.float32() * IPIXEL_DATA8_MAX) },
        x = PixelData8 { data8s = 0 },
    }
}

/* 16 BITS */
generate_random_pixel_data_ubgr16 :: #force_inline proc() -> BGR16 {
    return BGR16 {
        b = PixelData16 { data16 = cast(u16)(rand.float32() * UPIXEL_DATA16_MAX) },
        g = PixelData16 { data16 = cast(u16)(rand.float32() * UPIXEL_DATA16_MAX) },
        r = PixelData16 { data16 = cast(u16)(rand.float32() * UPIXEL_DATA16_MAX) },
        x = PixelData16 { data16 = 0 },
    }
}
/* SIGNED 16 BITS */
generate_random_pixel_data_sbgr16 :: #force_inline proc() -> BGR16 {
    return BGR16 {
        b = PixelData16 { data16s = cast(i16)(rand.float32() * IPIXEL_DATA16_MAX) },
        g = PixelData16 { data16s = cast(i16)(rand.float32() * IPIXEL_DATA16_MAX) },
        r = PixelData16 { data16s = cast(i16)(rand.float32() * IPIXEL_DATA16_MAX) },
        x = PixelData16 { data16s = 0 },
    }
}

/* 32 BITS */
generate_random_pixel_data_ubgr32 :: #force_inline proc() -> BGR32 {
    return BGR32 {
        b = PixelData32 { data32 = cast(u32)(rand.float32() * UPIXEL_DATA32_MAX) },
        g = PixelData32 { data32 = cast(u32)(rand.float32() * UPIXEL_DATA32_MAX) },
        r = PixelData32 { data32 = cast(u32)(rand.float32() * UPIXEL_DATA32_MAX) },
        x = PixelData32 { data32 = 0 },
    }
}
/* SIGNED 32 BITS */
generate_random_pixel_data_sbgr32 :: #force_inline proc() -> BGR32 {
    return BGR32 {
        b = PixelData32 { data32s = cast(i32)(rand.float32() * IPIXEL_DATA32_MAX) },
        g = PixelData32 { data32s = cast(i32)(rand.float32() * IPIXEL_DATA32_MAX) },
        r = PixelData32 { data32s = cast(i32)(rand.float32() * IPIXEL_DATA32_MAX) },
        x = PixelData32 { data32s = 0 },
    }
}

/* IMAGE DATA RANDOM GENERATION */

/* 8 BITS */
generate_random_image_ubgr8  :: #force_inline proc(data: ^[]BGR8) -> PixelTypeUUID {
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_ubgr8();
    return UNORM8_UUID;
}
/* SIGNED 8 BITS */
generate_random_image_sbgr8  :: #force_inline proc(data: ^[]BGR8) -> PixelTypeUUID {
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_sbgr8();
    return SNORM8_UUID;
}

/* 16 BITS */
generate_random_image_ubgr16 :: #force_inline proc(data: ^[]BGR16) -> PixelTypeUUID {
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_ubgr16();
    return UNORM16_UUID;
}
/* SIGNED 16 BITS */
generate_random_image_sbgr16 :: #force_inline proc(data: ^[]BGR16) -> PixelTypeUUID {
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_sbgr16();
    return SNORM16_UUID;
}

/* 32 BITS */
generate_random_image_ubgr32 :: #force_inline proc(data: ^[]BGR32) -> PixelTypeUUID {
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_ubgr32();
    return UNORM32_UUID;
}
/* SIGNED 32 BITS */
generate_random_image_sbgr32 :: #force_inline proc(data: ^[]BGR32) -> PixelTypeUUID {
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_sbgr32();
    return SNORM32_UUID;
}

@(private)
_generate_random_image_ubgr :: proc { generate_random_image_ubgr8, generate_random_image_ubgr16, generate_random_image_ubgr32 }
@(private)
_generate_random_image_sbgr :: proc { generate_random_image_sbgr8, generate_random_image_sbgr16, generate_random_image_sbgr32 }


generate_random_image_ubgr :: proc(using img: ^Image2(BGR($PixelDataT)), location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    data, _ = mem.make([]BGR(PixelDataT), size.x * size.y);
    info = BGR_UUID | (_generate_random_image_ubgr(&data) << 4);
}

generate_random_image_sbgr :: #force_inline proc(using img: ^Image2(BGR($PixelDataT)), location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    data, _ = mem.make([]BGR(PixelDataT), size.x * size.y);
    info = BGR_UUID | (_generate_random_image_sbgr(&data) << 4);
}

/* CONVERSION FUNCTIONS */

@(private)
ReinterpretPixelData :: struct($T: typeid) #raw_union {
    val: T,
}

reinterpret_pixel_data :: #force_inline proc($OutDataT: typeid, value: $InDataT) -> OutDataT {
    /* FORMULA: (original_value) * (max_pixel_new_value) / (max_pixel_former_value) */
    val := ((value._data * ((1 << size_of(OutDataT)) - 1)) / ((1 << size_of(InDataT)) - 1));
    return cast(OutDataT) ({
        _data = auto_cast val,
    });
}

reinterpret_pixel_bgr :: #force_inline proc($PixelBeforeT: typeid/BGR($InDataT), $PixelAfterT: typeid/BGR($OutDataT), value: PixelBeforeT) -> PixelAfterT {
    return cast(PixelAfterT) {
        b = reinterpret_pixel_data(OutDataT, value.b),
        g = reinterpret_pixel_data(OutDataT, value.g),
        r = reinterpret_pixel_data(OutDataT, value.r),
        x = reinterpret_pixel_data(OutDataT, value.x),
    };
}

reinterpret_pixel_rgba :: #force_inline proc($PixelBeforeT: typeid/RGBA($InDataT), $PixelAfterT: typeid/RGBA($OutDataT), value: PixelBeforeT) -> PixelAfterT {
    assert(false, "TO DO!");
    return cast(PixelAfterT) {
        r = reinterpret_pixel_data(InDataT, OutDataT, value.r),
        g = reinterpret_pixel_data(InDataT, OutDataT, value.g),
        b = reinterpret_pixel_data(InDataT, OutDataT, value.b),
        a = reinterpret_pixel_data(InDataT, OutDataT, value.a),
    };
}

@(private)
ReinterpretConversionTable :: struct {
    DataT: typeid,
    UUID: ImageInfoUUID,
}

@(private)
REINTERPRET_UTABLE := [?]ReinterpretConversionTable {
    { DataT = PixelData8,  UUID = UINT8_UUID  },
    { DataT = PixelData16, UUID = UINT16_UUID },
    { DataT = PixelData32, UUID = UINT32_UUID },
};

@(private)
REINTERPRET_STABLE := [?]ReinterpretConversionTable {
    { DataT = PixelData8,  UUID = SINT8_UUID  },
    { DataT = PixelData16, UUID = SINT16_UUID },
    { DataT = PixelData32, UUID = SINT32_UUID },
};

@(private)
query_uUUID :: proc(OutDataT: typeid) -> ImageInfoUUID {
    for utable in REINTERPRET_UTABLE {
        if utable.DataT == OutDataT do return utable.UUID;
    }
    return ImageInfoInvalid;
}

@(private)
query_sUUID :: proc(OutDataT: typeid) -> ImageInfoUUID {
    for stable in REINTERPRET_STABLE {
        if stable.DataT == OutDataT do return stable.UUID;
    } 
    return ImageInfoInvalid; 
}

reinterpret_image_bgr :: proc($ImageBeforeT: typeid/Image2(BGR($InDataT)), $ImageAfterT: typeid/Image2(BGR($OutDataT)), using img: ^ImageBeforeT) -> ImageAfterT {
    new_img: ImageAfterT;
    new_img.data = make([]BGR(OutDataT), size.x * size.y);
    new_img.size = size;
    new_img.info = BGR_UUID | (query_uUUID(OutDataT) << 4);

    for j in 0..<len(data) do new_img.data[j] = reinterpret_pixel_bgr(BGR(InDataT), BGR(OutDataT), data[j]);

    delete(data);

    return new_img;
}

reinterpret_image_rgba :: proc() {
    assert(false, "TO DO!");
}

reinterpret_image :: proc { reinterpret_image_bgr, reinterpret_image_rgba }

dump_image2 :: proc(using img: ^Image2($PixelType)) {
    delete(data);
}