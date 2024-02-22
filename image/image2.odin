package image

import "core:log"
import "core:mem"
import "core:math/rand"

/* ONE PIXEL VALUE */
PixelData :: struct($UNSIGNED: typeid, $SIGNED: typeid) #raw_union {
    data: UNSIGNED,
    data_s: SIGNED,
}

PixelData8  :: PixelData(u8, i8);
PixelData16 :: PixelData(u16, i16);
PixelData32 :: PixelData(u32, i32);

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

U_MAX :: #force_inline proc($T: typeid/PixelData($U, $S)) -> U {
    return (1 << (size_of(U) * 8)) - 1;
}
S_MAX :: #force_inline proc($T: typeid/PixelData($U, $S)) -> S {
    return (1 << (size_of(S) * 8)) - 1;
}

generate_random_pixel_data_ubgr :: #force_inline proc($PixelDataT: typeid/PixelData($U, $S)) -> BGR(PixelDataT) {
    return BGR(PixelDataT) {
        b = PixelDataT { data = cast(U)(rand.float32() * (1 << (size_of(U) * 8)) - 1) },
        g = PixelDataT { data = cast(U)(rand.float32() * (1 << (size_of(U) * 8)) - 1) },
        r = PixelDataT { data = cast(U)(rand.float32() * (1 << (size_of(U) * 8)) - 1) },
        x = PixelDataT { data = cast(U)(0) },
    };
}

generate_random_pixel_data_sbgr :: #force_inline proc($PixelDataT: typeid/PixelData($U, $S)) -> BGR(PixelDataT) {
    return BGR(PixelDataT) {
        b = PixelDataT { data_s = cast(S)(rand.float32() * (1 << size_of(S) - 1)) },
        g = PixelDataT { data_s = cast(S)(rand.float32() * (1 << size_of(S) - 1)) },
        r = PixelDataT { data_s = cast(S)(rand.float32() * (1 << size_of(S) - 1)) },
        x = PixelDataT { data_s = cast(S)(0) },
    }
}

/* IMAGE DATA RANDOM GENERATION */
generate_random_image_ubgr :: proc(using img: ^Image2(BGR($PixelDataT)), location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    data, _ = mem.make([]BGR(PixelDataT), size.x * size.y);
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_ubgr(PixelDataT);
    if info == 0 do info = BGR_UUID | (query_uUUID(PixelDataT) << 4);
}

generate_random_image_sbgr :: #force_inline proc(using img: ^Image2(BGR($PixelDataT)), location := #caller_location) {
    assert(size.x != 0 && size.y != 0, "Cannot generate an image without proper size!", location);
    data, _ = mem.make([]BGR(PixelDataT), size.x * size.y);
    for j in 0..<len(data) do data[j] = generate_random_pixel_data_sbgr(PixelDataT);
    if info == 0 do info = BGR_UUID | (query_sUUID(PixelDataT) << 4);
}

generate_random_image_urgba :: proc(using img: ^Image2(RGBA($PixelDataT)), location := #caller_location) {
    assert(false, "to do!");
}

generate_random_image_srgba :: #force_inline proc(using img: ^Image2(RGBA($PixelDataT)), location := #caller_location) {
    assert(false, "to do!");
}


/* CONVERSION FUNCTIONS */
reinterpret_pixel_data :: #force_inline proc($OutDataT: typeid, value: $InDataT) -> OutDataT {
    /* FORMULA: (original_value) * (max_pixel_new_value) / (max_pixel_former_value) */
    return cast(OutDataT) {
        _data = ((value._data * ((1 << size_of(OutDataT)) - 1)) / ((1 << size_of(InDataT)) - 1)),
    };
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
    /*>>>NOTE: NORMALIZED VALUES ARE IN THE "NORMALIZED.ODIN" */
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