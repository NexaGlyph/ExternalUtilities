package image

/* CONVERSION FUNCTIONS */
reinterpret_pixel_data :: #force_inline proc($OutDataT: typeid, value: $InDataT) -> OutDataT {
    /* FORMULA: (original_value) * (max_pixel_new_value) / (max_pixel_former_value) */
    return cast(OutDataT) {
        data = auto_cast ((value.data * ((1 << size_of(OutDataT)) - 1)) / ((1 << size_of(InDataT)) - 1)),
    };
}

reinterpret_pixel_bgr :: #force_inline proc($PixelAfterT: typeid/BGR($OutDataT), $PixelBeforeT: typeid/BGR($InDataT), value: PixelBeforeT) -> PixelAfterT {
    return cast(PixelAfterT) {
        b = reinterpret_pixel_data(OutDataT, value.b),
        g = reinterpret_pixel_data(OutDataT, value.g),
        r = reinterpret_pixel_data(OutDataT, value.r),
    };
}

reinterpret_pixel_rgba :: #force_inline proc($PixelAfterT: typeid/RGBA($OutDataT), $PixelBeforeT: typeid/RGBA($InDataT), value: PixelBeforeT) -> PixelAfterT {
    return cast(PixelAfterT) {
        r = reinterpret_pixel_data(OutDataT, value.r),
        g = reinterpret_pixel_data(OutDataT, value.g),
        b = reinterpret_pixel_data(OutDataT, value.b),
        a = reinterpret_pixel_data(OutDataT, value.a),
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

reinterpret_image_bgr_discard :: proc($ImageAfterT: typeid/Image2(BGR($OutDataT)), $ImageBeforeT: typeid/Image2(BGR($InDataT)), using img: ^ImageBeforeT) -> ImageAfterT {
    defer delete(data);
    return reinterpret_image_bgr(ImageAfterT, ImageBeforeT, img);
}

reinterpret_image_rgba_discard :: proc($ImageAfterT: typeid/Image2(RGBA($OutDataT)), $ImageBeforeT: typeid/Image2(RGBA($InDataT)), using img: ^ImageBeforeT) -> ImageAfterT {
    defer delete(data);
    return reinterpret_image_rgba(ImageAfterT, ImageBeforeT, img);
}

reinterpret_image_bgr :: proc($ImageAfterT: typeid/Image2(BGR($OutDataT)), $ImageBeforeT: typeid/Image2(BGR($InDataT)), using img: ^ImageBeforeT) -> ImageAfterT {
    new_img: ImageAfterT;
    new_img.data = make([]BGR(OutDataT), size.x * size.y);
    new_img.size = size;
    new_img.info = BGR_UUID | (query_uUUID(OutDataT) << 4);

    for j in 0..<len(data) do new_img.data[j] = reinterpret_pixel_bgr(BGR(OutDataT), BGR(InDataT), data[j]);

    return new_img;
}

reinterpret_image_rgba :: proc($ImageAfterT: typeid/Image2(RGBA($OutDataT)), $ImageBeforeT: typeid/Image2(RGBA($InDataT)), using img: ^ImageBeforeT) -> ImageAfterT {
    new_img: ImageAfterT;
    new_img.data = make([]RGBA(OutDataT), size.x * size.y);
    new_img.size = size;
    new_img.info = BGR_UUID | (query_uUUID(OutDataT) << 4);

    for j in 0..<len(data) do new_img.data[j] = reinterpret_pixel_rgba(RGBA(OutDataT), RGBA(InDataT), data[j]);

    return new_img;
}

reinterpret_image :: proc { reinterpret_image_bgr, reinterpret_image_rgba }
