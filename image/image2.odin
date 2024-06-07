package image

/* ONE PIXEL VALUE */
PixelData :: struct($UNSIGNED: typeid, $SIGNED: typeid) #raw_union {
    data: UNSIGNED,
    data_s: SIGNED,
}

PixelData8  :: PixelData(u8, i8);
PixelData16 :: PixelData(u16, i16);
PixelData32 :: PixelData(u32, i32);

/* BGRX PIXEL (FOR CONVENIENCE THE BGR IS PADDED BY THE 'X') */
BGR :: struct($PixelDataT: typeid) #align(4) {
    b, g, r: PixelDataT,
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

U_MAX :: #force_inline proc($T: typeid/PixelData($U, $S)) -> U {
    return (1 << (size_of(U) * 8)) - 1;
}
S_MAX :: #force_inline proc($T: typeid/PixelData($U, $S)) -> S {
    return (1 << (size_of(S) * 8)) - 1;
}

dump_image2 :: proc(using img: ^Image2($PixelType)) {
    delete(data);
}